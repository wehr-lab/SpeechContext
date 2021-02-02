% The Big Workflow
clear all
%% convert out files to raster data
pwd = 'd:\lab\djmaus\Data\sfm\2021-01-18_14-21-23_mouse-0098-NDT';
%convert_outfile_to_raster_format.m
%convert_outfile_to_raster_format_sfm.m
%use whatever is relevant, already completed this step in test run of data

%% declare your variables
raster_file_directory_name = 'D:\lab\djmaus\Data\sfm\2021-01-18_14-21-23_mouse-0098-NDT\';
save_prefix_name = '2021-01-18_14-21-23_mouse-0098-NDT\';
bin_width = 500; %in ms
sampling_interval = 50; %in ms
start_time = [];
end_time = [];
% if start_time and end_time are not declared NDT will generate values
%% convert raster files to binned data
%[saved_binned_data_file_name] = create_binned_data_from_raster_data(raster_file_directory_name, save_prefix_name, bin_width, sampling_interval);

%% set number and type of stimulus repetitions

load 'd:\lab\djmaus\Data\sfm\soundfile-iba-uda+WN80dB-full_duration--ISS-isi800ms-20reps.mat';
%label_names_to_use = 'stimuli.stimulus_description';

%recognize different stimuli
cd d:\lab\djmaus\Data\sfm\soundfile-iba-uda+WN80dB-full_duration--ISS-isi800ms-20reps_sourcefiles;
stimuli = dir('*.mat');
uniquestimuli = cell(30,1); %%%%% make an empty cell array the length of all the unique stimuli you have
%%%% also, you'll need to talk to Mike, see where the SS and WN are
%%%% located, and then add them to this process
wavforms = cell(30,1);
for i = 1:length(stimuli)
   uniquestimuli{i} = stimuli(i).name;
   load(uniquestimuli{i})
   wavforms{i} = sample.sample;
end
cd(pwd);

% We rewrote what is below, to do at the same time of finding the waveforms
% too
% descriptions = cell(32,1); %%%%% make an empty cell array the length of all the unique stimuli you have
% for i = 1:length(stimuli)
%     descriptions{i} = stimuli(i).stimulus_description;
% end
% uniquestimuli = unique(descriptions);
% binned_labels = 'stimuli.stimulus_description';

label_names_to_use = uniquestimuli;
binned_labels = label_names_to_use; %This appears to only be used in the function below to set up k repeats of each stimulus per neuron
specific_binned_label_name = binned_labels

%SFM 2/1/21 whether giving the above labels as the list of unique stimuli
%delivered or the raw list of stimuli delivered, somehow in basic_DS
%'label_names_to_use' is transformed into a string of gibberish

for k = 1:20
    [inds_of_sites_with_at_least_k_repeats, ~, ~, ~] = find_sites_with_k_label_repetitions(binned_labels, k, uniquestimuli);
    num_sites_with_k_repeats(k) = length(inds_of_sites_with_at_least_k_repeats);
end
%ds.site_to_use =
%find_sites_with_at_least_k_repeats_of_each_label(the_labels_to_use,
%num_cv_splits); %See error code in basic_DS Line 590
%k = # of repititions of each unique stimuli (20 for iba-uda x 32



%% create a DataSource (DS) object

binned_format_file_name = 'd:\lab\djmaus\Data\sfm\2021-01-18_14-21-23_mouse-0098-NDT\2021-01-18_14-21-23_mouse-0098-NDT_500ms_bins_50ms_sampled.mat';
binned_data_name = 'binned_data';

num_cv_splits = [1];
specific_label_name_to_use = uniquestimuli;
ds = basic_DS(binned_format_file_name, specific_label_name_to_use, num_cv_splits, 1);

%% creating a feature-processor (FP) object

the_feature_preprocessors{1} = zscore_normalize_FP;
%% creating a classifier (CL) object

the_classifier = max_correlation_coefficient_CL;

%% creating a cross-validator (CV) object

the_cross_validator = standard_resample_CV(ds, the_classifier, the_feature_preprocessors);

%set how many times the outer 'resample' loop is run, generally we use more
%than 2 resample runs which will give more accurate results but just
%throwing 2 in for now

the_cross_validator.num_resample_runs = 2;

%% running decoding analysis

decoding_results = the_cross_validator.run_cv_decoding;
save_file_name = '2021-01-18_14-21-23_mouse-0098-decoding-results';
save(save_file_name, 'decoding-results');

%% plotting results

result_names{1} = save_file_name;
plot_obj = plot_standard_results_object(result_names);
plot_obj.significant_events_times = 0;    %plot line when stimulus occured
plot_obj.plot_results;

%% plotting temporal cross training decoding accuracies

plot_obj = plot_standard_results_TCT_object(save_file_name);
plot_obj.significant_event_times = 0;
plot_obj.plot_results;
