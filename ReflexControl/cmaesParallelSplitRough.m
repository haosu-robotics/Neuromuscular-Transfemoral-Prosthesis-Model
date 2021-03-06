function costs = cmaesParallelSplitRough(gainsPop)
    global rtp InitialGuess
    %allocate costs vector and paramsets the generation
    popSize = size(gainsPop,2);

    numTerrains = 5;
    rampSlope = 0.0025;
    [groundX, groundZ, groundTheta] = generateGround('flat');

    costs = nan(popSize*numTerrains,1);
    paramSets = cell(popSize*numTerrains,1);

    %create param sets
    gainind = 1;
    for i = 1:numTerrains:(numTerrains*popSize)
        %set gains
        Gains = InitialGuess.*exp(gainsPop(:,gainind));

        paramSets{i} = Simulink.BlockDiagram.modifyTunableParameters(rtp, ...
            'LGainGAS',           Gains( 1), ...
            'LGainGLU',           Gains( 2), ...
            'LGainHAM',           Gains( 3), ...
            'LGainKneeOverExt',   Gains( 4), ...
            'LGainSOL',           Gains( 5), ...
            'LGainSOLTA',         Gains( 6), ...
            'LGainTA',            Gains( 7), ...
            'LGainVAS',           Gains( 8), ...
            'LKglu',              Gains( 9), ...
            'LPosGainGG',         Gains(10), ...
            'LSpeedGainGG',       Gains(11), ...
            'LhipDGain',          Gains(12), ...
            'LhipPGain',          Gains(13), ...
            'LkneeExtendGain',    Gains(14), ...
            'LkneeFlexGain',      Gains(15), ...
            'LkneeHoldGain1',     Gains(16), ...
            'LkneeHoldGain2',     Gains(17), ...
            'LkneeStopGain',      Gains(18), ...
            'LlegAngleFilter',    Gains(19), ...
            'LlegLengthClr',      Gains(20), ...
            'RGainGAS',           Gains(21), ...
            'RGainGLU',           Gains(22), ...
            'RGainHAM',           Gains(23), ...
            'RGainHAMCut',        Gains(24), ...
            'RGainKneeOverExt',   Gains(25), ...
            'RGainSOL',           Gains(26), ...
            'RGainSOLTA',         Gains(27), ...
            'RGainTA',            Gains(28), ...
            'RGainVAS',           Gains(29), ...
            'RKglu',              Gains(30), ...
            'RPosGainGG',         Gains(31), ...
            'RSpeedGainGG',       Gains(32), ...
            'RhipDGain',          Gains(33), ...
            'RhipPGain',          Gains(34), ...
            'RkneeExtendGain',    Gains(35), ...
            'RkneeFlexGain',      Gains(36), ...
            'RkneeHoldGain1',     Gains(37), ...
            'RkneeHoldGain2',     Gains(38), ...
            'RkneeStopGain',      Gains(39), ...
            'RlegAngleFilter',    Gains(40), ...
            'RlegLengthClr',      Gains(41), ...
            'simbiconGainD',      Gains(42), ...
            'simbiconGainV',      Gains(43), ...
            'simbiconLegAngle0',  Gains(44), ...
            'anklePgain',         Gains(45), ...
            'ankleDgain',         Gains(46), ...
            'ankleFilterPID',     Gains(47), ...
            'ankleFilterSEA',     Gains(48), ...
            'kneePgain',          Gains(49), ...
            'kneeDgain',          Gains(50), ...
            'kneeFilterPID',      Gains(51), ...
            'kneeFilterSEA',      Gains(52), ...
            'legAngleTgt',        Gains(53));

        %set ground heights
        for j = 0:(numTerrains-1)
            rng('default');
            rng(4*j);
            for k = 21:2:length(groundX)
                groundZ(k) = groundZ(k-2) + groundX(k-19)*2*(rand - 0.5)*rampSlope;
                groundZ(k+1) = groundZ(k);
            end
            %groundZ(end) = [];
            groundTheta = [atan(diff(groundZ)./diff(groundX)), 0];
    
            paramSets{i+j} = Simulink.BlockDiagram.modifyTunableParameters(paramSets{i}, ...
                'groundZ',     groundZ, ...
                'groundTheta', groundTheta);
        end
        gainind = gainind + 1;
    end
    rng('shuffle')

    %simulate each sample and store cost
    parfor i = 1:length(paramSets)
        costs(i) = evaluateCostParallel(paramSets{i});
    end

    %calculate median across terrains
    costs = reshape(costs,numTerrains,popSize)
    isinvalid = sum(isnan(costs))>1;
    costs = nanmean(costs);
    costs(isinvalid) = nan
    
