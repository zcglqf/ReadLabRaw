function info = step3_ConsistencyChecking( info_loc, varargin )
% Step3 finds the dimensions and check the consistency between Lab and Sin
% files.

% Initialize dimension data to zero
info_loc.dims.nCoils         = 0;
info_loc.dims.nKx            = 0;
info_loc.dims.nKy            = 0;
info_loc.dims.nKz            = 0;
info_loc.dims.nE3            = 0;
info_loc.dims.nLocations     = 0;
info_loc.dims.nEchoes        = 0;
info_loc.dims.nDynamics      = 0;
info_loc.dims.nCardiacPhases = 0;
info_loc.dims.nRows          = 0;
info_loc.dims.nMixes         = 0;
info_loc.dims.nMeasurements  = 0;  %these substucture names are used for record the number of unique values for every fieldname.

% BEGIN: check that the number of mixes are equal between sin and lab
% data.
mixval_norm_data = info_loc.labels.Mix.vals(info_loc.idx.NORMAL_DATA);
mixidx_norm_data = info_loc.idx.NORMAL_DATA;
info_loc.dims.nMixes         = length(unique(mixval_norm_data));                  % number of unique mix values.
assert(info_loc.dims.nMixes == info_loc.sin.dims.nMixes, 'nMixes values read from sin and lab files MUST equal');
% END

% BEGIN: check that the number of echoes/loc/dyn/card/row/meas/extra of each mix are equal between sin and lab
% data.
ecoval_norm_data = info_loc.labels.Echo.vals(info_loc.idx.NORMAL_DATA);
for imix = 0 : info_loc.dims.nMixes - 1
    mixidx_norm_data_i = mixidx_norm_data(mixval_norm_data == imix);
    info_loc.dims.nEchoes(imix+1)        = length(unique(info_loc.labels.Echo.vals(mixidx_norm_data_i)));
    % BEGIN: check nKx/nKy/nKz for each (echo, mix) are equal between sin
    % and lab
    for ieco = 0 : info_loc.dims.nEchoes(imix+1) - 1        
        ecoidx_norm_data_i = mixidx_norm_data(mixval_norm_data == imix & ecoval_norm_data == ieco);
        progcnt = unique(info_loc.labels.ProgressCnt.vals(ecoidx_norm_data_i));
        datasiz = unique(info_loc.labels.DataSize.vals(ecoidx_norm_data_i));
        assert(length(progcnt) == length(datasiz), 'ProgressCount and DataSize much be equal under each mix and echo.');
        nKx = unique(datasiz ./ progcnt);
        assert(length(nKx) == 1, 'Vector size of one readout must be constant under each mix and echo.');
        switch info_loc.raw_format
            case 0
                info_loc.dims.nKx(imix+1, ieco+1) = nKx / 2.0 / 2.0;
            case 6
                info_loc.dims.nKx(imix+1, ieco+1) = nKx / 2.0 / 2.0 / 2.0;
            otherwise
                error('not supported raw format');
        end
        info_loc.dims.nKy(imix+1, ieco+1) = length(unique(info_loc.labels.E1.vals(ecoidx_norm_data_i)));
        info_loc.dims.nKz(imix+1, ieco+1) = length(unique(info_loc.labels.E2.vals(ecoidx_norm_data_i)));
        info_loc.dims.nE3(imix+1, ieco+1) = length(unique(info_loc.labels.E3.vals(ecoidx_norm_data_i)));
    end
    % END    
    info_loc.dims.nLocations(imix+1)     = length(unique(info_loc.labels.Location.vals(mixidx_norm_data_i)));
    info_loc.dims.nDynamics(imix+1)      = length(unique(info_loc.labels.Dynamic.vals(mixidx_norm_data_i)));
    info_loc.dims.nCardiacPhases(imix+1) = length(unique(info_loc.labels.CardiacPhase.vals(mixidx_norm_data_i)));
    info_loc.dims.nRows(imix+1)          = length(unique(info_loc.labels.Row.vals(mixidx_norm_data_i)));
    info_loc.dims.nMeasurements(imix+1)  = length(unique(info_loc.labels.Measurement.vals(mixidx_norm_data_i)));
    info_loc.dims.nExtraAttrs(imix+1)    = length(unique(info_loc.labels.ExtraAtrr.vals(mixidx_norm_data_i)));
end

assert(isequal(info_loc.dims.nEchoes,        info_loc.sin.dims.nEchoes),        'nEchoes values read from sin and lab files MUST equal');
assert(isequal(info_loc.dims.nLocations,     info_loc.sin.dims.nLocations),     'nLocations values read from sin and lab files MUST equal; Remove this for SenseRefScan');
assert(isequal(info_loc.dims.nDynamics,      info_loc.sin.dims.nDynamics),      'nDynamics values read from sin and lab files MUST equal');
assert(isequal(info_loc.dims.nCardiacPhases, info_loc.sin.dims.nCardiacPhases), 'nCardiacPhases values read from sin and lab files MUST equal');
assert(isequal(info_loc.dims.nRows,          info_loc.sin.dims.nRows),          'nRows values read from sin and lab files MUST equal');
assert(isequal(info_loc.dims.nMeasurements,  info_loc.sin.dims.nMeasurements),  'nMeasurements values read from sin and lab files MUST equal');
assert(isequal(info_loc.dims.nExtraAttrs,    info_loc.sin.dims.nExtraAttrs),    'nExtraAttrs values read from sin and lab files MUST equal');
assert(isequal(info_loc.dims.nKx,            info_loc.sin.dims.nKx),            'nKx MUST be a unique value for each stack, mix or echo; For None uniform EPI (or DWI)/Spectroscopy/non-cart sequence, you may need to slightly modify the program in step1 to find the right size of readout vector');
assert(all(info_loc.dims.nKy <=  info_loc.sin.dims.nKy),                        'nKy values read from lab file MUST be smaller than or equal to those from sin file');
assert(all(info_loc.dims.nKz <=  info_loc.sin.dims.nKz),                        'nKz values read from lab file MUST be smaller than or equal to those from sin file');
assert(isequal(info_loc.dims.nE3,            info_loc.sin.dims.nE3),            'nE3 MUST be a unique value for each stack, mix or echo');

% END

% BEGIN: check the number of channels of each stack are equal between sin and lab
% data.
locs_norm_data_vec = info_loc.labels.Location.vals(info_loc.idx.NORMAL_DATA);     % Location number of each norm data vector
prog_cnt_norm_data = info_loc.labels.ProgressCnt.vals(info_loc.idx.NORMAL_DATA);  % ProgressCnt (= nr of channels) of each norm data vector
datasize_norm_data = info_loc.labels.DataSize.vals(info_loc.idx.NORMAL_DATA);     % Data size of each norm data vector

[locs, lab_idx, ic] = unique(locs_norm_data_vec, 'last');                         % return unique location numbers, and for each unique loc number, return the index of the last one  
stacknrs = zeros(size(locs));
progrcnt = zeros(size(locs));
datasize = zeros(size(locs));

for iloc = locs
    stacknrs(iloc+1) = info_loc.sin.dims.loc_to_stack(iloc+1);                    % stack nr of each location.
    progrcnt(iloc+1) = prog_cnt_norm_data(lab_idx(iloc+1));                       % nr of channels of each location.
    datasize(iloc+1) = datasize_norm_data(lab_idx(iloc+1));
end

[stks, stk_idx, ic] = unique(stacknrs, 'last');                                   % return unique stack numbers.
stk_nr_channels     = progrcnt(stk_idx);                                          % return nr of channels of each stack.

assert(length(stks) == info_loc.sin.dims.nStacks, 'Number of stacks obtained from SIN and LAB files MUST equal!, Remove this for SenseRefScan');

info_loc.dims.nCoils         = stk_nr_channels;
assert(all(sort(info_loc.dims.nCoils) == sort(info_loc.sin.dims.nCoils)), 'Channel numbers obtained from SIN and LAB file MUST equal!'); % ZCG, failure for CoilSurveyScanData.
% END


info = info_loc;

% ------------------------- Coding History --------------------------------
% - 2017-01-09, C. Zhao, chenguang.z.zhao@philips.com.
%   copied the matlab package that I believe is originally from welcheb. 
%   Started adding DDAS capabibity on top of this matlab package.
% - 2017-07-31, C. Zhao,
%   Previously, data dimensions are obtained from lab file. now they are
%   read from sin file. Yet, we still keep this file for consistency
%   checking. File name changes to step3_ConsistencyChecking from step2_LoadOpt.
% - 2018-02-08, C. Zhao,
%   Add mix and echo dependent for each of the dimensions.
