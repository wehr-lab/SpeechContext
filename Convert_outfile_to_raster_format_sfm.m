function Convert_outfile_to_raster_format_sfm
% convert outfile to raster format
datadir='D:\lab\djmaus\Data\sfm\GrandKilosort0296CombinedOutfiles';   %Enter directory of OUTfiles to be converted here


aindex=2;
dindex=2;
%should also add silent sound as an additional stimulus type
cd(datadir)
d=dir('outPSTH*.mat');
for i=1:length(d)
    fprintf('\ncell %d of %d', i, length(d))
    outfilename=d(i).name;
    load(outfilename)
    cellid=outfilename(9:end-4);
    
    
    xlimits=out.xlimits;
    num_trials =out.nrepsOFF(:,aindex, dindex);
    num_time_points=out.samprate*(1/1000)*(xlimits(2)-xlimits(1));
    
    % M1OFF: [30×2×2×100 struct]
    
    % count actual num_trials
    num_trials=0;
    for stimID=1:out.numsourcefiles
        nr=out.nrepsOFF(stimID, aindex, dindex);
        for rep=1:nr
            num_trials=num_trials+1;
        end
    end
    raster_data=zeros(num_trials, round(num_time_points));
    
    r=0;
    for stimID=1:out.numsourcefiles
        nr=out.nrepsOFF(stimID, aindex, dindex);
        for rep=1:nr
            r=r+1;
            spiketimes=out.M1OFF(stimID, aindex, dindex, rep).spiketimes;
            spiketimes=spiketimes-xlimits(1);
            %convert ms spiketimes to raster format (samples)
            spiketimes_rast=1+round(spiketimes*out.samprate/1000);
            
            raster_data(r,spiketimes_rast)=1;
            raster_labels.sourcefile{r}=out.sourcefiles{stimID};
        end
    end
    
    raster_site_info.IL=out.IL;
    raster_site_info.Nclusters=out.Nclusters;
    raster_site_info.channel=out.channel;
    raster_site_info.cell=out.cell;
    raster_site_info.xlimits=out.xlimits;
    raster_site_info.amps=out.amps;
    raster_site_info.durs=out.durs;
    raster_site_info.sourcefiles=out.sourcefiles;
    raster_site_info.numamps=out.numamps;
    raster_site_info.numsourcefiles=out.numsourcefiles;
    raster_site_info.numdurs=out.numdurs;
    raster_site_info.samprate=out.samprate;
    raster_site_info.datadir=out.datadir;
    raster_site_info.outfilename=outfilename;
    raster_site_info.nb=out.nb;
    raster_site_info.stimlog=out.stimlog;
    raster_site_info.run_on=datestr(now);
    raster_site_info.generated_by=mfilename;
    raster_site_info.alignment_event_time=-xlimits(1)*out.samprate/1000;
    
    datadirstr=strsplit(out.datadir, '\');
    raster_filename=sprintf('%s_%s_raster_data', datadirstr{end},cellid);
    if ~exist('raster_files', 'dir') mkdir raster_files;end
    cd raster_files
    
%     save( raster_filename, 'raster_data', 'raster_labels', 'raster_site_info') %Original, but file over 2GB, so let's save it betterly.
    %%Sam's compression (LOSSLESS):
    [I] = find(raster_data);
    raster_size = size(raster_data);
    save( raster_filename, 'I', 'raster_size', 'raster_labels', 'raster_site_info')
   %%Sam's decompression (to be used in whatever the script is that loads the raster files:
%     load(raster_filename);
%     raster_data = zeros(raster_size);
%     raster_data(I) = 1; 

    cd(datadir)
end
    
    
    
    
    
    
    