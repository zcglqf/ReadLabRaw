function [data, info ] = step6_ReadRawData( info_loc, rawname )
% read raw data and store them in a high dimension array (13 dims). The dim
% names from inner to outer most dimensions are recorded in info.dimfields.

% Dimension names
dimfields = {'Kx','Ky','Kz','Coil','E3','Location','Echo','Dynamic','CardiacPhase','Row','ExtraAttrs','Measurement','Mix'};
data = [];

% Progress update
total_normal_data = length(info_loc.idx.NORMAL_DATA );
extracted_normal_data = 0;
h = waitbar(0,'Decoding RAW data, please wait...');

% Open *.raw file, and get the fid
fidraw = fopen(rawname,'r','ieee-le');
if fidraw < 0
  error('cannot open RAW file: %s', rawname); 
end
info.nLoadedLabels = 0;

data = zeros(info_loc.dims.nKx(1),... % info_loc.sin.dims.nKx, ...
             max(info_loc.sin.dims.nKy), ...
             max(info_loc.sin.dims.nKz), ...
             max(info_loc.sin.dims.nCoils), ...
             info_loc.sin.dims.nE3, ...
             info_loc.sin.dims.nLocations, ...
             info_loc.sin.dims.nEchoes, ...
             info_loc.sin.dims.nDynamics, ...
             info_loc.sin.dims.nCardiacPhases, ...
             info_loc.sin.dims.nRows, ...
             info_loc.sin.dims.nExtraAttrs, ...
             info_loc.sin.dims.nMeasurements, ...
             info_loc.sin.dims.nMixes );

sizeflag = size(data);
sizeflag(1) = [];                                        % remove Coil and Kx dimensions
sizeflag(3) = [];
flags = zeros(sizeflag, 'uint8');                        % this flag array is used to mark is an RO vector is retrieved already or not.

for label_idx = info_loc.idx.NORMAL_DATA                                

    iKy          = info_loc.labels.E1.vals(label_idx) + 1;          assert(iKy >= 1 && iKy <= max(info_loc.sin.dims.nKy))
    iKz          = info_loc.labels.E2.vals(label_idx) + 1;          assert(iKz >= 1 && iKz <= max(info_loc.sin.dims.nKz))
    iE3          = info_loc.labels.E3.vals(label_idx) + 1;          assert(iE3 >= 1 && iE3 <= max(info_loc.sin.dims.nE3))
    iLocation    = info_loc.labels.Location.vals(label_idx) + 1;    assert(iLocation >= 1)
    iEcho        = info_loc.labels.Echo.vals(label_idx) + 1;        assert(iEcho >= 1)
    iDynamic     = info_loc.labels.Dynamic.vals(label_idx) + 1;     assert(iDynamic >= 1)
    iCardiac     = info_loc.labels.CardiacPhase.vals(label_idx) + 1;assert(iCardiac >= 1)
    iRow         = info_loc.labels.Row.vals(label_idx) + 1;         assert(iRow >= 1)
    iExtra       = info_loc.labels.ExtraAtrr.vals(label_idx) + 1;   assert(iExtra >= 1)
    iMeas        = info_loc.labels.Measurement.vals(label_idx) + 1; assert(iMeas >= 1)
    iMix         = info_loc.labels.Mix.vals(label_idx) + 1;         assert(iMix >= 1)
    
    
    % stack nr 
    loc_nr = info_loc.labels.Location.vals(label_idx); 
    stack_nr = info_loc.sin.dims.loc_to_stack(loc_nr + 1);%
     
    %     %label_idx = info.idx.NORMAL_DATA(n);
    %
    %     % debug only
    %     echo_nr = info_loc.labels.Echo.vals(label_idx);
    %     pe_nr   = int32(info_loc.labels.E1.vals(label_idx)) - 29;
    %     sl_nr   = int32(info_loc.labels.E2.vals(label_idx)) - 42;
    %     me_nr   = int32(info_loc.labels.Measurement.vals(label_idx)); % measurement nr
    %     %fprintf(1, 'pe = %d, 3d = %d\n\t', pe_nr, sl_nr);
    %     if pe_nr == 0 && echo_nr == 0 && loc_nr == 0 && sl_nr == 0 && me_nr == 0
    %         disp('to here');
    %     end
    %     % debug only
  
   
    %     if info_loc.labels.Location.vals(label_idx) == 0
    %         disp(dim_assign_indices_full_array);%ZCG debug only
    %     end
    
    if ~flags( iKy, iKz, iE3, iLocation, iEcho, iDynamic, iCardiac, iRow, iExtra, iMeas, iMix)     
        
        info_loc.nLoadedLabels = info_loc.nLoadedLabels + 1;
    
        byte_offset = info_loc.fseek_offsets(label_idx);
        fseek(fidraw, byte_offset, 'bof');
        %raw_data_fread_size = info_loc.labels.DataSize.vals(label_idx);
        %raw_data_fread_size = double(info_loc.dims.nCoils * info_loc.dims.nKx * 2); 
      
        % ZCG, read data based on raw_format
        switch info_loc.labels.RawFormat.vals(label_idx)
            case 0 % int16
                raw_data_fread_size = info_loc.labels.DataSize.vals(label_idx); % nr. of bytes
                nCoils = raw_data_fread_size / (info_loc.dims.nKx*4); % one complex number occupies 4 bytes
                assert(~isempty(find(info_loc.dims.nCoils == nCoils)));
                raw_data_fread_size = raw_data_fread_size / 2;             % nr. of int16
                rawdata_1d = double(fread(fidraw, raw_data_fread_size, 'int16'));
                rawdata_1d = rawdata_1d(1:2:end) + 1i * rawdata_1d(2:2:end);
            case 1 % f16
                error('not supported raw format');
            case 2 % int32
                raw_data_fread_size = info_loc.labels.DataSize.vals(label_idx); % nr. of bytes
                nCoils = raw_data_fread_size / (info_loc.dims.nKx*8); % one complex number occupies 8 bytes
                assert(~isempty(find(info_loc.dims.nCoils == nCoils)));
                raw_data_fread_size = raw_data_fread_size / 4;             % nr. of int32
                rawdata_1d = double(fread(fidraw, raw_data_fread_size, 'int32'));
            case 3 % float32
                raw_data_fread_size = info_loc.labels.DataSize.vals(label_idx); % nr. of bytes
                nCoils = raw_data_fread_size / (info_loc.dims.nKx*8); % one complex number occupies 8 bytes
                assert(~isempty(find(info_loc.dims.nCoils == nCoils)));
                raw_data_fread_size = raw_data_fread_size / 4;             % nr. of flt32
                rawdata_1d = double(fread(fidraw, raw_data_fread_size, 'float32'));
            case {4,5} % coded
                error('not supported raw format');
            case 6 % coded
                nCoils = info_loc.labels.DataSize.vals(label_idx) / (info_loc.dims.nKx*8); % one complex number occupies 8 bytes
                assert(~isempty(find(info_loc.dims.nCoils == nCoils)));                  
                raw_data_fread_size = info_loc.labels.CodedDataSize.vals(label_idx); % nr. of bytes, 6512
                rawdatacoded = uint32(fread(fidraw, raw_data_fread_size / 4, 'uint32'));
                %multichavector = decode_rawfmt6( rawdatacoded, info_loc.dims.nKx, nCoils );
                multichavector = decode( double(rawdatacoded), double(info_loc.dims.nKx), double(nCoils) );
                rawdata_1d = multichavector; % double(fread(fidraw, raw_data_fread_size, 'int16'));
        end
        
        if(length(rawdata_1d)~=info_loc.dims.nKx * nCoils)
            disp('not expected vector size, ignored.....');
            continue;
        end

        rawdata_2d = reshape(rawdata_1d, info_loc.dims.nKx, nCoils); % info_loc.dims.nCoils);
    
        rawdata_2d = nonlin_corr( info_loc, label_idx, rawdata_2d );
        
        % basic correction: DC fixed, PDA, and (random) phase correction.
        if info_loc.sin.enable_dc_offset_corr 
            if ~isempty(info_loc.sin.dc_fixed_arr)
                %
                % for DDAS, dc fixed is not necessary because all DC offset
                % values are zero. Probably becuase signals are in digital and
                % there is no DC drift?
                % for CDAS, dc_fixed_arr in sin file is used for this
                % correction.
                for internal_nr = 1 : nCoils
                    % internal_nr -> external_nr
                    externChannelNr = info_loc.sin.dims.measured_channels_of_stacks{stack_nr+1}(internal_nr) + 1;
                    % external_nr -> receiver_nr
                    receiverNr = info_loc.sin.dims.receiver_nrs(externChannelNr) + 1;
                    % receiver_nr -> dc_fixed offset value 
                    dc_fixed = info_loc.sin.dc_fixed_arr(receiverNr);                
                    rawdata_2d(:, internal_nr) = rawdata_2d(:,internal_nr) - dc_fixed;
                end
            end
        end
        
        if info_loc.sin.enable_pda
            % for DDAS, enable_pda is alway FLASE, skip the implementation
            % for now.
            % for CDAS, the pda correction parameters can be read from
            % pda_ampl_factors in sin file.
            if ~isempty(info_loc.sin.pda_ampl_factors)
                for internal_nr = 1 : nCoils
                    externChannelNr = info_loc.sin.dims.measured_channels_of_stacks{stack_nr+1}(internal_nr) + 1;
                    gainIndex = info_loc.labels.GainSetting.vals(label_idx)+1;
                    pdaAmplFactor = info_loc.sin.pda_ampl_factors(gainIndex, externChannelNr);                
                    rawdata_2d(:, internal_nr) = rawdata_2d(:,internal_nr) * pdaAmplFactor;
                end                
            end
        end
        
        % Phase correction, must do.
        if true
            if info_loc.sin.relative_fear_bandwidth > 0.0
                relativeFearBandwidth = info_loc.sin.relative_fear_bandwidth;
                RandomPhase = double(typecast(info_loc.labels.RandomPhase.vals(label_idx), 'int16'));
                MeasurementPhase = double(info_loc.labels.MeasurementPhase.vals(label_idx));

                phaseFloat = (RandomPhase * pi) / double(intmax('int16')); % + MeasurementPhase * pi / 2.0;
                %phase = %cos(phaseFloat) + 1i*sin(phaseFloat);
                phaseIncr = relativeFearBandwidth * phaseFloat * double(0:info_loc.dims.nKx-1)' + MeasurementPhase * pi / 2.0;%cos( relativeFearBandwidth * phaseFloat) + 1i*sin( relativeFearBandwidth * phaseFloat);
                phacorr = cos(-phaseFloat - phaseIncr) + 1i*sin(-phaseFloat - phaseIncr); %conj(phase) * phaseIncr .^ (0:info_loc.dims.nKx-1);
                phacorr = kron(ones(1, nCoils), phacorr);
                rawdata_2d = rawdata_2d .* phacorr;                
            else
                RandomPhase = double(info_loc.labels.RandomPhase.vals(label_idx)); % double(info_loc.labels.RandomPhase.vals(label_idx));
                MeasurementPhase = double(info_loc.labels.MeasurementPhase.vals(label_idx));
                c = exp (- 1i * pi * (2 * RandomPhase / (2^16-1) + MeasurementPhase / 2));
                rawdata_2d = rawdata_2d * c;
            end
        end %end-if        
        
        % debug only
        %         if info_loc.labels.E1.vals(label_idx) == 176 && info_loc.labels.Location.vals(label_idx) == 0
        %             save matlab_vactor.mat 'rawdata_2d' '-mat';
        %         end
   
        % account for measurement sign
        if info_loc.labels.MeasurementSign.vals(label_idx)
            rawdata_2d = flipud(rawdata_2d);      
        end %end-if
    
        data( :, iKy, iKz, 1:size(rawdata_2d,2), iE3, iLocation, iEcho, iDynamic, iCardiac, iRow, iExtra, iMeas, iMix ) = rawdata_2d;        
    
    else
        disp('Read out vector has been filled already, ( iKy, iKz, iE3, iLocation, iEcho, iDynamic, iCardiac, iRow, iExtra, iMeas, iMix) = %s', ...
            num2str([ iKy, iKz, iE3, iLocation, iEcho, iDynamic, iCardiac, iRow, iExtra, iMeas, iMix]));
    end %end-if
  
    extracted_normal_data = extracted_normal_data + 1;
    waitbar(extracted_normal_data / total_normal_data, h, 'Decoding RAW data, please wait...');

end %end-for label_idx-loop

close(h) 

fclose(fidraw);
% Calculate total raw data blobs
% size_data = size(data);
% max_img_dims = size_data(3:end);
% info.nDataLabels = prod(max_img_dims);


info = info_loc;
info.dimfields = dimfields;

end




% ------------------------- Coding History --------------------------------
% - 2017-01-09, C. Zhao, chenguang.z.zhao@philips.com.
%   Copied the matlab package that I believe is originally from welcheb. 
%   Started adding DDAS capabibity on top of this matlab package.
%
% - 2017-04-20, C. Zhao
%   DDAS raw data reading (decoding) capability added.
%
% - 2017-05-04. C. Zhao
%   Put the decoding code into sub function decode_rawfmt6
%
% - 2017-10-26. Y. Huang
%   implement DDAS decoding in c code to accelerate data reading.
%
% - 2018-02-12. C. Zhao
%   House keeping and fix bug in dc fixed correction for CDAS.
%

