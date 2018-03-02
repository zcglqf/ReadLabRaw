function info = step4_ReadNoneLinearityCorr( info_loc, rawname)
% The following two things are performed:
% - DC fixed correction data reading 
% - None linearity correction data reading

%open the *.raw file and get the fid
fidraw = fopen(rawname,'r','ieee-le');
if fidraw < 0
    error('cannot open RAW file: %s', rawname);
end % end-if

info = info_loc;
max_channel_nr = length(info_loc.sin.dims.channel_names);
info.NON_LIN_CORR.nonLinLevels = cell(1, max_channel_nr);
info.NON_LIN_CORR.nonLinCorrValues = cell(1, max_channel_nr);

% BEGIN, DC fixed correction data reading. For DDAS, the DC offsets for all
% external channels are recorded under one label. However, it seems DC_FIXED_DATA read from
% RAW file are always zero for each channel, so this part of code doesn't
% see to be necessary for DDAS (but let's keep it). For CDAS, dc correction
% data is read from sin file, ref 'step1' info.dc_fixed_arr.
for k = 1:length(info_loc.idx.DC_FIXED_DATA),
    dc_fixed_idx = info_loc.idx.DC_FIXED_DATA(k);
    
    byte_offset = info_loc.fseek_offsets(dc_fixed_idx); % zcg, to here
    fseek(fidraw, byte_offset, 'bof');   %from the start of the file
    
    % normalzation factor
    low_word = info_loc.labels.Destination.vals(dc_fixed_idx);
    high_word = info_loc.labels.RconJobId.vals(dc_fixed_idx);
    normalization_factor = typecast(uint32(bitshift(high_word, 16) + low_word), 'single');
    
    raw_data_fread_size = info_loc.labels.DataSize.vals(dc_fixed_idx); % nr. of bytes
    assert(raw_data_fread_size == max_channel_nr * 8, 'number of channels %d / 8 must equal to raw data size of dc_fixed_data %d', max_channel_nr, raw_data_fread_size );
    
    dc_fixed_data = double(fread(fidraw, raw_data_fread_size/4, 'float32'));
    dc_fixed_data = dc_fixed_data(1:2:end) + 1i*dc_fixed_data(2:2:end);
end

MAX_SHORT_VALUE = 32767.0;
ARSRC_STD_NORMALIZATION_FACTOR = 10000.0;
normalization_factor = normalization_factor / ( MAX_SHORT_VALUE * ARSRC_STD_NORMALIZATION_FACTOR);

info.DC_FIXED_DATA = dc_fixed_data * normalization_factor;
% END

% BEGIN, None linearity correction data reading. Each channel has a
% seperate label to store the correction data.
for k = 1:length(info_loc.idx.ARSRC_LABEL_TYPE_NON_LIN),
    non_lin_idx = info_loc.idx.ARSRC_LABEL_TYPE_NON_LIN(k);
    
    byte_offset = info_loc.fseek_offsets(non_lin_idx); 
    fseek(fidraw, byte_offset, 'bof');   %from the start of the file
    
    % external channel number
    low_bype  = info_loc.labels.ControlType.vals(non_lin_idx);
    high_byte = info_loc.labels.MonitoringFlag.vals(non_lin_idx);
    channel_nr = bitshift(high_byte, 8) + low_bype;
    assert(channel_nr < max_channel_nr, 'channel nr %d must be smaller than %d', channel_nr, max_channel_nr);
    
    % nr of breakpoints
    low_bype  = info_loc.labels.MeasurementPhase.vals(non_lin_idx);
    high_byte = info_loc.labels.MeasurementSign.vals(non_lin_idx);
    nr_breakpoints = bitshift(high_byte, 8) + low_bype;
    
    raw_data_fread_size = info_loc.labels.DataSize.vals(non_lin_idx); % nr. of bytes
    assert(raw_data_fread_size == nr_breakpoints * 3 * 4, 'none linearity correction datasize %d / 3 / 4 must match with nr of breakpoints %d...', raw_data_fread_size, nr_breakpoints );
    
    non_lin_data = double(fread(fidraw, [3, nr_breakpoints], 'float32'));
    nonLinLevels = non_lin_data(1,:);
    nonLinCorrValues = non_lin_data(2,:) + 1i * non_lin_data(3,:);
    
    [nonLinLevels, idx] = sort(nonLinLevels);
    nonLinCorrValues = nonLinCorrValues(idx);
    
    info.NON_LIN_CORR.nonLinLevels{channel_nr+1} = nonLinLevels;
    info.NON_LIN_CORR.nonLinCorrValues{channel_nr+1} = nonLinCorrValues;
end
% END

fclose(fidraw);

end

% ------------------------- Coding History --------------------------------
% - 2017-05-22, C. Zhao, first version in Matlab R2012b. This script is used
% - to read non linearity correction data from RAW file.


