% load synthetic speech context outfiles and extract spikes into a matrix so we can do some sanity checking

clear
tic
cd('/Users/sammehan/Documents/Wehr Lab/SpeechContext2021/Synthetic Test Data') % Set directory

%%% Settings
group = 'Group12';                                                           % What subdirectory in here?
plot_switch = 1;                                                            % Do you want all of the diagnostic plots? (neurometric curve plots not included)
no_context_switch = 1;                                                      % Do you want all trials or just BA-DA?
fit_model_switch = 1;                                                       % Do you need to open Classification Learner and fit a model?

cd(group)
if ~exist('GroupDataTable.mat', 'file')
    d = dir('outPSTH*.mat');
    for i = 1:length(d)
        fprintf('\n%d/%d', i, length(d))
        outfilename = sprintf('outPSTH_synth_ch%dc%d.mat', i, i);
        out = load(outfilename);
        data(i).M1OFF = out.out.M1OFF;
        data(i).mM1OFF = out.out.mM1OFF;
    end
    save('GroupDataTable', 'data');
    nreps = max(out.out.nreps(:));
else
    load('GroupDataTable.mat');
    nreps = 40;
end

for i = 1:length(data)
    data(i).M1OFF = data(i).M1OFF([1 3 4 5 6 7 8 9 10 2 11 13 14 15 16 17 18 19 20 12 21 23 24 25 26 27 28 29 30 22], :, :, :);
    data(i).mM1OFF = data(i).mM1OFF([1 3 4 5 6 7 8 9 10 2 11 13 14 15 16 17 18 19 20 12 21 23 24 25 26 27 28 29 30 22], :, :);
end

% trial-averaged
if ~exist('CellsByStimDatatable.mat', 'file')
    start = 190;
    stop = 350;
    for j = 1:length(data)
        mM1OFF = data(j).mM1OFF(:,2,2,1);
        for k = 1:length(mM1OFF)
            spiketimes = mM1OFF(k).spiketimes;
            spikecount = length(find(spiketimes >= start & spiketimes <= stop));
            sc(k) = spikecount;
        end
        cellsbystim_datatable(j,:) = sc;
    end
    save('CellsByStimDatatable.mat', 'cellsbystim_datatable', 'scsorted');
else
    load('CellsByStimDatatable.mat');
end
if plot_switch == 1
    figure
    imagesc(cellsbystim_datatable(:, 1:10))
    colormap jet
    xlabel('stimulus')
    ylabel('cell')
    title([group, 'trial-averaged'])

    figure
    plot(cellsbystim_datatable(1,1:30), cellsbystim_datatable(25,1:30), 'o')
    ax = axis;
    xlabel('cell 1')
    ylabel('cell 25')
    figure
    for i = 1:size(cellsbystim_datatable, 2)
        text(cellsbystim_datatable(1,i), cellsbystim_datatable(25, i),int2str(i))
    end
    xlabel('cell 1')
    ylabel('cell 25')
    axis(ax)
end

%%%
% Single trials

if ~exist('TotalTrials&MTrials.mat', 'file')
    TotalTrialsByStim = [];
    for j = 1:length(data)
        M1OFF = data(j).M1OFF(:,2,2,:);
        for k = 1:size(M1OFF, 1)
            for rep = 1:size(M1OFF, 4)
                spiketimes = M1OFF(k, 1, 1, rep).spiketimes;
                spikecount = length(find(spiketimes >= start & spiketimes <= stop));
                sc(k, rep) = spikecount;
            end
        end
        Mtrials(j,:,:) = sc;                                                % Mtrials is cells x stimulus x rep
        TotalTrialsByStim = [TotalTrialsByStim scsorted];
    end
    save('TotalTrials&MTrials.mat', 'TotalTrialsByStim', 'Mtrials');
else
    load('TotalTrials&MTrials.mat');
end
if no_context_switch == 1
    TotalTrialsByStim = TotalTrialsByStim(1:10, :)';
else
    TotalTrialsByStim = TotalTrialsByStim';
end
if plot_switch == 1
    figure
    imagesc(TotalTrialsByStim)
    xlabel('stimulus')
    ylabel('cells and trials')
    title([group, 'single trials'])
end

if ~exist('TrialAveragedExemplars.mat', 'file')
    clear response CellsTrialAveragedExemplars
    CellsTrialAveragedExemplars = [];
    k = 0;
    for i = [1 10] % BA and DA only
        for j = 1:nreps
            k = k + 1;
            StimID2(k) = i;
            CellsTrialAveragedExemplars(:, k) = Mtrials(:, i, j);
        end
    end
    save('TrialAveragedExemplars.mat', 'CellsTrialAveragedExemplars', 'StimID2');
else
    load('TrialAveragedExemplars.mat');
end
if plot_switch == 1
    figure
    imagesc(CellsTrialAveragedExemplars)
    xlabel('stimuli and trials')
    ylabel('cells')
    title([group, 'single trials (CellsTrialAveragedExemplars)'])
end
% CellsTrialAveragedExemplars is cells x (stim * reps) and only has stimuli 1 and 10 (BA and DA)
% CellsTrialAveragedExemplars is designed to be input for classification learner

if ~exist('CellsTrialAveragedAllBADA.mat', 'file')
    clear response CellsTrialAveragedBADA
    CellsTrialAveragedAllBADA = [];
    k = 0;
    for i = [1:30] % All BA-DA
        for j = 1:nreps
            k = k + 1;
            StimID3(k) = i;
            CellsTrialAveragedAllBADA(:, k) = Mtrials(:, i, j);
        end
    end
% CellsTrialAveragedBADA is cells x (stim * reps)
% CellsTrialAveragedBADA is designed to be input for classification learner
    coerce_switch = 1;
    if coerce_switch == 1
        StimID3_Coerce = zeros(length(StimID3), 1);
        for i = 1:length(StimID3)
            if StimID3(i) == 1 || StimID3(i) == 10
                StimID3_Coerce(i) = StimID3(i);
            elseif StimID3(i) == 2 || StimID3(i) == 3 || StimID3(i) == 4 || StimID3(i) == 5
                StimID3_Coerce(i) = 1;
            elseif StimID3(i) == 6 || StimID3(i) == 7 || StimID3(i) == 8 || StimID3(i) == 9
                StimID3_Coerce(i) = 10;
            else
            end
        end
    end
    save('CellsTrialAveragedAllBADA.mat', 'CellsTrialAveragedAllBADA', 'StimID3', 'StimID3_Coerce');
else
    if no_context_switch == 0
        load('CellsTrialAveragedAllStims.mat');
    elseif no_context_switch == 1
        load('CellsTrialAveragedAllBADA.mat');
    end
end
if plot_switch == 1
    figure
    imagesc(CellsTrialAveragedBADA)
    xlabel('stimuli and trials')
    ylabel('cells')
    title([group, 'single trials (CellsTrialAveragedBADA)'])
end

%%% End Preprocessing

if fit_model_switch == 1
    classificationLearner
    f = gcf;
    uiwait(gcf);
end

load('Group12ExemplarsLinSVM.mat');
% if no_context_switch == 0
    yfit = Group12ExemplarsLinSVM.predictFcn(CellsTrialAveragedAllStims);
% elseif no_context_switch == 1
%     yfit = Group12ExemplarsLinDisc.predictFcn(CellsTrialAveragedBADA);
% end
totalfitresults = sum(yfit == StimID3_Coerce) / length(StimID3_Coerce);

confusionmatrixallstims = zeros(30, 3);
for i = 1:length(yfit)
    curr_PredStimID = yfit(i);
    curr_TrueStimID = StimID3(i);
    if curr_PredStimID == 1
        confusionmatrixallstims(curr_TrueStimID, 1) = confusionmatrixallstims(curr_TrueStimID, 1) + 1;
    elseif curr_PredStimID == 10
        confusionmatrixallstims(curr_TrueStimID, 2) = confusionmatrixallstims(curr_TrueStimID, 2) + 1;
    end
end
for j = 1:30                                                                %  or length(confusionmatrixallstims)
    confusionmatrixallstims(j, 3) = confusionmatrixallstims(j, 2)/(confusionmatrixallstims(j, 1) + confusionmatrixallstims(j, 2));
end

figure
plot(1:10, confusionmatrixallstims((1:10), 3), 'bo-');
if no_context_switch == 0
    hold on
    plot(1:10, confusionmatrixallstims((11:20), 3), 'go-');
    hold on
    plot(1:10, confusionmatrixallstims((21:30), 3), 'ro-');
end
xlabel('Ba-Da Spectrum');
ylabel('% of Stims Labeled Da');
title([group, ' Neurometric Curve (Trained Exemplars vs. Test 1-30)'])

toc