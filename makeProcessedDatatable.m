function [ProcessedDatatable] = makeProcessedDatatable(varargin)

    ProcessAllDirsSwitch = 1;                                                   % Logical on whether to process each directory individually or all dirs kilosorted together
    masterdirs = varargin;
    if isempty(varargin)
        error('You gotta add some directories to process!')
    end

    for i = 1:length(masterdirs)
        cd(masterdirs{i});
        MasterDir = masterdirs{i};
        EphysPath = masterdirs{i};
        temp_string = strsplit(EphysPath, '20');
        LocalDataRoot = temp_string{1};
        [SortedUnitsFile] = ProcessSpikes(EphysPath, LocalDataRoot, ProcessAllDirsSwitch);
        temp_str = strsplit(EphysPath, '-');
        mouseID = temp_str{end};

        [Events, StartAcquisitionSec] = ProcessEvents(pwd);
        if strcmp(Events(1).type, 'soundfile') == 1
            MasterEvents.Speech = Events;
            fieldnames_speech = fieldnames(MasterEvents.Speech);
            MasterEvents.Tuning = struct([]);
        elseif strcmp(Events(1).type, 'tone') == 1
            MasterEvents.Tuning = Events;
            fieldnames_tuning = fieldnames(MasterEvents.Tuning);
            MasterEvents.Speech = struct([]);
        else 
            error("This doesn't appear to be recording either tuning curves or speech context protocols!")
        end
        InitialStartAcquisitionSec = StartAcquisitionSec;

        load('dirs.mat');
        for j = 2:length(dirs)
            cd(dirs{j})
            try
                load(fullfile(MasterDir,'RecLengths.mat'))
            catch
                % load rez, which contains number of samples of each recording 1=1, 2=1+2,
                % 3=1+2+3, etc
                load(fullfile(MasterDir,'rez.mat'))
                L=(rez.ops.recLength)/sp.sample_rate;
                save(fullfile(MasterDir,'RecLengths.mat'),'L')
            end
            [TempEvents, TempStartAcquisitionSec] = ProcessEvents(pwd);
            for m = 1:length(TempEvents)
                TempEvents(m).message_timestamp_sec = TempEvents(m).message_timestamp_sec + L(j - 1);
                TempEvents(m).soundcard_trigger_timestamp_sec = TempEvents(m).soundcard_trigger_timestamp_sec + L(j - 1);
            end
            start_acq_samp = L(j - 1)*(30e3);                               %Shouldn't be hardcoded
            for m = 1:length(TempEvents)
                TempEvents(m).message_timestamp_samples = TempEvents(m).message_timestamp_samples + start_acq_samp;
            end
            
            clear temp_stim_types
            for i = 1:length(TempEvents)
                temp_stim_types{i} = TempEvents(i).type;
            end
            types_of_stims = unique(temp_stim_types);
            if length(types_of_stims) == 4
                for q = 1:length(TempEvents)
                    if strcmp(TempEvents(q).type, 'tone') == 1
                        if isempty(MasterEvents.Tuning)
                            MasterEvents.Tuning = [MasterEvents.Tuning, TempEvents(q)];
                        else
                            end_index = length(MasterEvents.Tuning) + 1;
                            for fields = fieldnames(MasterEvents.Tuning)
                                for z = 1:length(fields)
                                    fname = fields{z};
                                    MasterEvents.Tuning(end_index).(fname) = TempEvents(q).(fname);
                                end
                            end
                        end
                    elseif strcmp(TempEvents(q).type, 'soundfile') == 1
                        if isempty(MasterEvents.Speech)
                            MasterEvents.Speech = [MasterEvents.Speech, TempEvents(q)];
                        else
                            end_index = length(MasterEvents.Speech) + 1;
                            for fields = fieldnames(MasterEvents.Speech)
                                for z = 1:length(fields)
                                    fname = fields{z};
                                    MasterEvents.Speech(end_index).(fname) = TempEvents(q).(fname);
                                end
                            end
                        end
                    elseif strcmp(TempEvents(q).type, 'silentsound') == 1 && TempEvents(q).duration == 363.7340
                        end_index = length(MasterEvents.Speech) + 1;
                        for fields = fieldnames(MasterEvents.Speech)
                            for z = 1:length(fields)
                                fname = fields{z};
                                MasterEvents.Speech(end_index).(fname) = TempEvents(q).(fname);
                            end
                        end
                    elseif strcmp(TempEvents(q).type, 'silentsound') == 1 && TempEvents(q).duration == 25
                        end_index = length(MasterEvents.Tuning) + 1;
                        for fields = fieldnames(MasterEvents.Tuning)
                            for z = 1:length(fields)
                                fname = fields{z};
                                MasterEvents.Tuning(end_index).(fname) = TempEvents(q).(fname);
                            end
                        end
                    elseif strcmp(TempEvents(q).type, 'whitenoise') == 1 && TempEvents(q).duration == 363.7340
                        end_index = length(MasterEvents.Speech) + 1;
                        for fields = fieldnames(MasterEvents.Speech)
                            for z = 1:length(fields)
                                fname = fields{z};
                                MasterEvents.Speech(end_index).(fname) = TempEvents(q).(fname);
                            end
                        end
                    elseif strcmp(TempEvents(q).type, 'whitenoise') == 1 && TempEvents(q).duration == 25
                        end_index = length(MasterEvents.Tuning) + 1;
                        for fields = fieldnames(MasterEvents.Tuning)
                            for z = 1:length(fields)
                                fname = fields{z};
                                MasterEvents.Tuning(end_index).(fname) = TempEvents(q).(fname);
                            end
                        end
                    else
                        error("Couldn't resolve stimuli, manually check stimlog")
                        pause
                    end
                end
            elseif length(types_of_stims) == 3
                if strcmp(TempEvents(1).type, 'soundfile') == 1
                    MasterEvents.Speech = [MasterEvents.Speech, TempEvents];
                elseif strcmp(TempEvents(1).type, 'tone') == 1
                    if isfield(MasterEvents.Tuning, 'sourcefile')
                        MasterEvents.Tuning = rmfield(MasterEvents.Tuning, 'sourcefile');
                    end
                    if isfield(MasterEvents.Tuning, 'sourcepath')
                        MasterEvents.Tuning = rmfield(MasterEvents.Tuning, 'sourcepath');
                    end
                    MasterEvents.Tuning = [MasterEvents.Tuning, TempEvents];
                end
            else
                error("Unexpected number of types of stimuli, what experiment did you run?")
            end
        end
        savename = strcat(EphysPath, '\MasterEvents-', mouseID);
        save(savename, 'MasterEvents', 'StartAcquisitionSec');
    end

end


