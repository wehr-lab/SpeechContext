function [Events, StartAcquisitionSec] = ProcessEvents(varargin)
% Extract stimulus and network message information into a data table for a
% single OpenEphys directory. Input should be a string of a data directory
% to be sorted
    

    if isstring(varargin)
        datadir = varargin;
        cd(datadir)
    else
        error('Could not parse directory name, check to see if the directory name was input correctly')
    end

    messagesfilename='messages.events';
    [messages] = GetNetworkEvents(messagesfilename);
    Eventsfilename='all_channels.events';
    [all_channels_data, all_channels_timestamps, all_channels_info] = load_open_ephys_data(Eventsfilename);
    load('notebook.mat');
    sampleRate=all_channels_info.header.sampleRate;
    try
        [Events, StartAcquisitionSec] = GetEventsAndSCT_Timestamps(messages, sampleRate, all_channels_timestamps, all_channels_data, all_channels_info, stimlog);
    catch
        warning('Unable to get events and timestamps, something went wrong in %s during recording.', char(datadir))
        Events = [];
    end
   
    save(fullfile(datadir,'EventsSCT_Trigs.mat'), 'Events', 'StartAcquisitionSec');
end