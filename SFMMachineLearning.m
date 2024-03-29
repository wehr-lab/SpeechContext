% SFM Matlab Machine Learning

clear
tic
raster_switch = 0;

if raster_switch == 1
    outdir = {};                                              % Enter dir/dirs with outfiles to be rastered - SFM 9/8/21
    convert_outfile_to_raster_format_sfm(outdir);
    cd(ourdir{end});
end

% % Preprocessing of Raster Data

rasterdir = 'F:\Data\sfm\Synthetic Test Data\Group6';                        % Enter dir with rastered data if skipping the step from above - SFM 9/8/21
cd(rasterdir)
rasterlist = dir('*.mat');
preprocess_switch = 1;
decompression_switch = 0;
real_data = 0;                                                % Binary switch on whether to organize synthetic data, won't work with real data - SFM 9/13/21


if real_data == 0
    for i = 1:length(rasterlist)                              % Let's put everything in order just in case, but only for synth data! - SFM 9/3/21
        presplit = strsplit(rasterlist(i).name, '_');
        presplit2 = strsplit(presplit{5}, 'c');
        dirindex = str2num(presplit2{3});
        fixeddir(dirindex) = rasterlist(i);
    end
    rasterlist = fixeddir;
end
    
if preprocess_switch == 1    
    if decompression_switch == 1
        for i = 1:length(rasterlist)                          % Decompress any sparse coding scheme - SFM 9/8/21
            load(rasterlist(i).name);
            if exist('I', 'var')
                raster_data = zeros(raster_size);
                raster_data(I) = 1;
            else
            end
        end
    else
        %load(rasterlist(1).name);  % 80 reps/stim             % Still need at least one raster loaded to create other variables, assuming they are all the same - SFM 9/10/21
        load(rasterlist(11).name); % 100 reps/stim
    end                                                       

    stimlog = raster_labels.sourcefile';                      % Simplify the labels, but keep the old ones - SFM 9/8/21
    uniquestims = {};
    for i = 1:600                                             % NOTE: We are assuming all cells have the same stimlog (should be the case) - SFM 9/9/21
        presplit = strsplit(stimlog{i}, '_');
        presplit2 = strsplit(presplit{4}, '+');
        newlabel = strcat(presplit2{1}, '-', presplit{5});
        uniquestimindex = str2double(presplit{5});
        stim{i} = newlabel;
        uniquestims{uniquestimindex} = newlabel;
    end
    uniquestims = uniquestims';                               % The more flexible way to do this is to only shorten labels for the first cycle and then replicate that X times for X number of repeats - SFM 9/13/21

    uniquestimuli = unique(stimlog);                          % Let's put everything in order just in case - SFM 9/3/21
    for k = 1:length(uniquestimuli)                           % Need to have stimuli names numbered in order - SFM 9/14/21
        presplit = strsplit(uniquestimuli{k}, '_');
        dirindex = str2num(presplit{5});
        stimdir(dirindex) = uniquestimuli(k);
    end                             
    uniquestimuli = stimdir';

    stimindices = [];
    tempstimindices = [];
    for j = 1:length(uniquestimuli)
        for i = 1:length(stimlog)
            if strcmp(uniquestimuli{j}, stimlog{i}) == 1
                tempstimindices = [tempstimindices i];
            end
        end
        stimindices(j,:) = tempstimindices;
        tempstimindices = [];
    end

    stimindices = stimindices';
end
toc

% % Table Construction

xlim = -181.8672;                                               % Shouldn't ever change, if so use round(out.xlimits(1), 4) - SFM 9/8/21
samprate = raster_site_info.samprate;                           % Also shouldn't change, but just in case we will get it from the raster/out data - SFM 9/8/21
start_time = 175 - xlim;                                  
end_time = 370 - xlim;                                          % Use 247.5 for only the consonant, 370 for full phoneme - SFM 9/23/21
start_time_samp = round((start_time/1000) * samprate);
end_time_samp = round((end_time/1000) * samprate);
hertzconv = round((1 / ((end_time - start_time) / 1000)), 2);   % Factor to multiple spike counts by to convert to Hertz - SFM 9/9/21
hertzconv_switch = 0;                                           % Switch on whether to convery spike counts to Hz - SFM 9/10/21
min_reps = 40;                                                 % Set minimum number of repetitions each cell needs to have to be included - SFM 9/14/21
min_indices = min_reps * length(uniquestimuli);

list_of_stims_to_use = {uniquestims{1}, uniquestims{10}};
% list_of_stims_to_use = {uniquestims{1}, uniquestims{10}, uniquestims{11}, uniquestims{20}, uniquestims{21}, uniquestims{30}}; 

split_switch = 0;                                               % Binary on whether to create training and test split tables or one big table - SFM 9/10/21
split_point = 0.5;                                              % Portion of data you want selected for training the model - SFM 9/9/21

if split_switch == 1
    dataindices_train = [];
    dataindices_test = [];
    for k = 1:length(list_of_stims_to_use)
        stim_split = strsplit(list_of_stims_to_use{k}, '-');
        index_to_use = str2double(stim_split{end});
        curr_stims = stimindices(:, index_to_use);
        first_n_indices = round(length(curr_stims) * split_point);
        curr_stims = curr_stims(randperm(length(curr_stims)));
        if k == 1
            dataindices_train = [curr_stims(1:first_n_indices)]; 
            dataindices_test = [curr_stims((first_n_indices + 1):end)];
        else    
            dataindices_train = [dataindices_train; curr_stims(1:first_n_indices)];
            dataindices_test = [dataindices_test; curr_stims((first_n_indices + 1):end)];
        end
    end
    dataindices_train = sort(dataindices_train, 'ascend');
    dataindices_test = sort(dataindices_test, 'ascend');
else
    dataindices = [];
    for k = 1:length(list_of_stims_to_use)
        stim_split = strsplit(list_of_stims_to_use{k}, '-');
        index_to_use = str2double(stim_split{end});
        curr_stims = stimindices(:, index_to_use);
        if k == 1
            dataindices = [curr_stims];
        else
            dataindices = [dataindices; curr_stims];
        end
    end
    dataindices = sort(dataindices, 'ascend');
end

clear datatable datatable_train datatable_test                                                
if split_switch == 1
    datatable_train = [];
    datatable_test = [];
else
    datatable = []; 
end

exclude_cells = [];                                             % Array containing sites/neurons to exclude from the model - SFM 9/9/21
list_of_cells_excluded = {};                                    % If a cell doesn't have the minimum num of repeats, return the name just in case - SFM 9/14/21
manual_cell_curation_switch = 0;                                % Logical switch on whether to manually put neurons into training or testing groups - SFM 9/15/21
%All Examplars
% list_of_cell_names = {'raster_combined_ch9c449_combined0095.mat', 'raster_combined_ch16c341_combined0095.mat', 'raster_combined_ch18c567_combined0095.mat', 'raster_combined_ch23c181_combined0095.mat', 'raster_combined_ch26c171_combined0095.mat', 'raster_combined_ch31c193_combined0095.mat', 'raster_combined_ch0c263_combined0098.mat', 'raster_combined_ch3c636_combined0098.mat', 'raster_combined_ch12c237_combined0098.mat', 'raster_combined_ch19c222_combined0098.mat', 'raster_combined_ch21c666_combined0098.mat', 'raster_combined_ch22c483_combined0098.mat', 'raster_combined_ch31c377_combined0098.mat', 'raster_combined_ch3c1757_combined0295.mat', 'raster_combined_ch6c2239_combined0295.mat', 'raster_combined_ch10c1810_combined0295.mat', 'raster_combined_ch14c1910_combined0295.mat', 'raster_combined_ch14c2287_combined0295.mat', 'raster_combined_ch33c1952_combined0295.mat', 'raster_combined_ch35c1978_combined0295.mat', 'raster_combined_ch38c1463_combined0295.mat', 'raster_combined_ch42c2062_combined0295.mat', 'raster_combined_ch45c465_combined0295.mat', 'raster_combined_ch48c2096_combined0295.mat', 'raster_combined_ch52c929_combined0295.mat', 'raster_combined_ch55c2140_combined0295.mat', 'raster_combined_ch57c2152_combined0295.mat', 'raster_combined_ch61c1712_combined0295.mat', 'raster_combined_ch61c2188_combined0295.mat', 'raster_combined_ch61c2196_combined0295.mat', 'raster_combined_ch12c187_combined0296.mat', 'raster_combined_ch34c251_combined0296.mat', 'raster_combined_ch44c313_combined0296.mat'}'; 
%BA/DA
% list_of_cell_names = {'raster_combined_ch9c449_combined0095.mat', 'raster_combined_ch16c341_combined0095.mat', 'raster_combined_ch18c567_combined0095.mat', 'raster_combined_ch23c181_combined0095.mat', 'raster_combined_ch26c171_combined0095.mat', 'raster_combined_ch6c2239_combined0295.mat', 'raster_combined_ch14c1910_combined0295.mat', 'raster_combined_ch14c2287_combined0295.mat', 'raster_combined_ch33c1952_combined0295.mat', 'raster_combined_ch35c1978_combined0295.mat'}; 
%IBA/IDA
% list_of_cell_names = {'raster_combined_ch0c263_combined0098.mat', 'raster_combined_ch3c636_combined0098.mat', 'raster_combined_ch12c237_combined0098.mat', 'raster_combined_ch21c666_combined0098.mat', 'raster_combined_ch31c377_combined0098.mat', 'raster_combined_ch48c2096_combined0295.mat', 'raster_combined_ch52c929_combined0295.mat', 'raster_combined_ch57c2152_combined0295.mat', 'raster_combined_ch61c2188_combined0295.mat', 'raster_combined_ch61c2196_combined0295.mat', 'raster_combined_ch34c251_combined0296.mat'};
%UBA/UDA
% list_of_cell_names = {'raster_combined_ch31c193_combined0095.mat', 'raster_combined_ch19c222_combined0098.mat', 'raster_combined_ch22c483_combined0098.mat', 'raster_combined_ch3c1757_combined0295.mat', 'raster_combined_ch10c1810_combined0295.mat', 'raster_combined_ch38c1463_combined0295.mat', 'raster_combined_ch42c2062_combined0295.mat', 'raster_combined_ch45c465_combined0295.mat', 'raster_combined_ch55c2140_combined0295.mat', 'raster_combined_ch61c1712_combined0295.mat', 'raster_combined_ch12c187_combined0296.mat', 'raster_combined_ch44c313_combined0296.mat'};
% List name format of cell names here (someone in the future reading it can automate this, I only need it once!!!!!) - SFM 9/15/21

if manual_cell_curation_switch == 1
    ListedCell = 0;
    UnlistedCell = 0;
    for iCell = 1:length(rasterlist)
        if sum(strcmp(rasterlist(iCell).name, list_of_cell_names(:))) == 1
            ListedCell = ListedCell + 1;
            selectedrasterlist(ListedCell) = rasterlist(iCell);
        else
            UnlistedCell = UnlistedCell + 1;
            unselectedrasterlist(UnlistedCell) = rasterlist(iCell);
        end
    end
%     selectedrasterlist = sort(selectedrasterlist.name, 'ascend');
%     unselectedrasterlist = sort(unselectedrasterlist.name, 'ascend');
    rasterlist = selectedrasterlist;                            % Quick and dirty way to make this new table - SFM 9/16/21
    
    
end

for i = 1:length(rasterlist)                                    % Construct the data table from the raster data - SFM 9/8/21
    if ~isempty(setdiff(i, exclude_cells))
        clear raster_data I raster_labels raster_size
        load(rasterlist(i).name);
        if ~exist('raster_data', 'var')
            raster_data = zeros(raster_size);
            raster_data(I) = 1;
        end
        if split_switch == 1
            for j = 1:length(dataindices_train)                 % ASSUMING the same number of training and testing indices (this is a faulty assumption) - SFM 9/10/21
                Ind_train(j) = sum(raster_data(dataindices_train(j), start_time_samp:end_time_samp));
            end
            for j = 1:length(dataindices_test)
                Ind_test(j) = sum(raster_data(dataindices_test(j), start_time_samp:end_time_samp));
            end
        else
            if length(raster_labels.sourcefile) >= min_indices
                for j = 1:length(dataindices)
                    Ind(j) = sum(raster_data(dataindices(j), start_time_samp:end_time_samp));
                end
                if i == 1
                    if split_switch == 1
                        datatable_train = [Ind_train];
                        datatable_test = [Ind_test];
                    else
                        datatable = [Ind];
                    end
                else i ~= 1;
                    if split_switch == 1
                        datatable_train = [datatable_train; Ind_train];
                        datatable_test = [datatable_test; Ind_test];
                    else
                        datatable = [datatable; Ind];
                    end
                end
            else
                list_of_cells_excluded{i} = rasterlist(i).name;
            end
        end
    end
end
toc

list_of_cells_excluded = list_of_cells_excluded(~cellfun('isempty', list_of_cells_excluded));
if hertzconv_switch == 1
    try
        datatable_train = datatable_train * hertzconv;
        datatable_test = datatable_test * hertzconv;
    catch
        datatable = datatable * hertzconv;
    end
end

stim_name = 'BA-DA';

if split_switch == 1
    datatable_supervised = table(datatable_train);
    datatable_unsupervised = table(datatable_test);
%     true_stims = {'DA', 'DA', 'DA', 'DA', 'DA', 'DA', 'DA', 'DA', 'DA', 'BA', 'BA', 'BA', 'BA', 'BA', 'BA', 'BA', 'BA', 'BA', 'BA'}';
    datatable_supervised = addvars(datatable_unsupervised, true_stims);
else
    datatable_unsupervised = table(datatable);
    true_stims_synth6_19 = {'DA', 'DA', 'DA', 'DA', 'DA', 'DA', 'DA', 'DA', 'DA', 'BA', 'BA', 'BA', 'BA', 'BA', 'BA', 'BA', 'BA', 'BA', 'BA'}';
%    true_stims = {'IBA', 'UDA', 'UDA', 'IBA', 'BA', 'DA', 'DA', 'BA', 'BA', 'IDA', 'UBA', 'DA', 'DA', 'UDA', 'IBA', 'DA', 'IDA', 'BA', 'UBA', 'UBA', 'IDA', 'UDA', 'UDA', 'UBA', 'IDA', 'IBA', 'UBA', 'IBA', 'UBA', 'IDA', 'IBA', 'DA', 'BA'}';
    %BA/DA
%     Stim = {'BA', 'DA', 'DA', 'BA', 'DA', 'DA', 'DA', 'BA', 'DA', 'BA'}';
    %IBA/IDA
%     Stim = {'BA', 'BA', 'DA', 'BA', 'DA', 'DA', 'DA', 'BA', 'BA', 'DA', 'BA'}';
    %UBA/UDA
%     Stim = {'DA', 'DA', 'BA', 'BA', 'DA', 'BA', 'BA', 'DA', 'DA', 'BA', 'BA', 'BA'}';
    datatable_supervised = addvars(datatable_unsupervised, true_stims_synth6_19);
end

groupname = strsplit(rasterdir, '\');
datatype = groupname{4};
groupname = groupname{end};
savedir = 'F:\Data\sfm\DataTables';
cd(savedir);
numtables = length(dir('*.mat'));
save_switch = 1;
cells_used = length(rasterlist) - length(list_of_cells_excluded);
% full_trial_switch = 1;
% average_switch = 1;

if save_switch == 1
    if strcmp(datatype, 'Synthetic Test Data')
%         savename_supervised = strcat('Synth', groupname, 'Supervised_', stim_name, num2str(cells_used), 'Cells_', num2str(numtables + 1));
        savename_unsupervised = strcat('Synth', groupname, 'Unsupervised_', stim_name, num2str(cells_used), 'Cells_', num2str(numtables + 1));
    else
%         savename_supervised = strcat('ExperimentalDataSupervised_', stim_name, num2str(cells_used), 'Cells_', num2str(min_reps), 'MinReps_', num2str(length(list_of_stims_to_use)), 'LabelsUsed_', num2str(numtables + 1));
        savename_unsupervised = strcat('ExperimentalDataUnsupervised_', stim_name, num2str(cells_used), 'Cells_', num2str(min_reps), 'MinReps_', num2str(length(list_of_stims_to_use)), 'LabelsUsed_', num2str(numtables + 1));
    end
%     save(savename_supervised, 'datatable_supervised', 'list_of_cells_excluded'); 
    save(savename_unsupervised, 'datatable_unsupervised', 'list_of_cells_excluded');
end

modeldir = 'F:\Data\sfm\Machine Learning Models';
cd(modeldir);

quick_results_switch = 0;
if quick_results_switch == 1
    [resultstable] = quickresults(list_of_stims_to_use, min_reps);
end
%


