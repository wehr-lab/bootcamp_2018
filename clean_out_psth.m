function clean_out_psth(out_fn)

% read out file

% set desired fields and names depending on stim type
load(out_fn);
stimtype = out.stimlog(1).type;
switch stimtype
    case 'clicktrain'
        field_list = {'cell','icis','durs','MtOFF','samprate','stimlog'};
        rename_list = {'cell','icis','durs','spiketimes','samprate','stimlog'};
        stim_idx = {'icis'};
end

% get desired fields, renaming
clean_out = struct();
for field=1:length(field_list)
    clean_out.(rename_list{field}) = out.(field_list{field});
end

% unnest spiketimes
spiketimes = {};
n_cells = prod(size(clean_out.spiketimes));
for i = 1:n_cells
    spiketimes(i) = {clean_out.spiketimes(i).spiketimes};
end
% reshape
spiketimes = reshape(spiketimes,size(clean_out.spiketimes));
clean_out.spiketimes = spiketimes;

% unnest stimlog params
stim_params = struct2table(clean_out.stimlog(1).param);
for i=2:length(clean_out.stimlog)
    stim_params = [stim_params;struct2table(clean_out.stimlog(i).param)];
end
clean_out.stimparams = stim_params;

% save
[save_dir,fn,~] = fileparts(out_fn);
if length(save_dir) <= 1
    save_dir = pwd;
end
split_fn = strsplit(fn, 'c');
save_fn = ['out_',split_fn{end},'_clean.mat'];

out = clean_out;

save(fullfile(save_dir,save_fn),'out');


%%%%%%%%%
% create long format spiketimes
reps = size(out.spiketimes);
reps = reps(end);

spike_table = table();
switch length(stim_idx)
    case 1
        [stim_reps,stim_idx1] = meshgrid(1:reps,out.(stim_idx{1}));
        for i=1:prod(size(out.spiketimes))
            spikes = out.spiketimes{i}';
            nspikes = length(spikes);
            idx1 = repmat(stim_idx1(i),nspikes,1);
            rep  = repmat(stim_reps(i),nspikes,1);
            spike_table = [spike_table;table(spikes,idx1,rep)];
        end
        spike_table.Properties.VariableNames{'idx1'} = stim_idx{1};
        
    case 2
        [stim_idx1,stim_idx2, stim_reps] = meshgrid(1:reps,out.(stim_idx{1}), out.(stim_idx{2}));
end

% save
save_fn = ['out_',split_fn{end},'_spikes.csv'];
writetable(spike_table,save_fn);

end

