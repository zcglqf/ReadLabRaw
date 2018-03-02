function info = step5_ReadFRC( info_loc, rawname)
% read FRC noise data in the *.raw file
% the FRC noise data is saved in the structure INFO (info_loc.FRC_NOISE)

%open the *.raw file and get the fid
fidraw = fopen(rawname,'r','ieee-le');
if fidraw < 0
    error('cannot open RAW file: %s', rawname);
end

% BEGIN, Read FRC noise data. FRC noise is recorded under one single label.
% However, additional FRC noise might be collected for different mix and stack.
for k = 1:length(info_loc.idx.FRC_NOISE_DATA),%find the index of FRC_NOISE_DATA vectors
    frc_noise_idx = info_loc.idx.FRC_NOISE_DATA(k);%one FRC_NOISE_DATA vector refers to one coil.
    
    byte_offset = info_loc.fseek_offsets(frc_noise_idx);
    fseek(fidraw, byte_offset, 'bof');   %from the start of the file
    
    switch info_loc.labels.RawFormat.vals(frc_noise_idx)
        case 0 % int16
            raw_data_fread_size = info_loc.labels.DataSize.vals(frc_noise_idx); % nr. of bytes
            nCoils = raw_data_fread_size / (info_loc.dims.nKx(1)*info_loc.sin.frc_oversample_noise_factor*4); % one complex number occupies 4 bytes
            %cuidi: assert(~isempty(find(info_loc.dims.nCoils == nCoils)));
            raw_data_fread_size = raw_data_fread_size / 2;             % nr. of int16
            rawdata_1d = double(fread(fidraw, raw_data_fread_size, 'int16'));
            frc_noise_samples_per_coil = raw_data_fread_size / 2 / nCoils; %info_loc.dims.nCoils;
            rawdata_1d = rawdata_1d(1:2:end) + 1i * rawdata_1d(2:2:end);
        case 1 % f16
            error('not supported raw format');
        case 2 % int32
            raw_data_fread_size = info_loc.labels.DataSize.vals(frc_noise_idx); % nr. of bytes
            nCoils = raw_data_fread_size / (info_loc.dims.nKx(1)*info_loc.sin.frc_oversample_noise_factor*8); % one complex number occupies 8 bytes
            assert(~isempty(find(info_loc.dims.nCoils == nCoils)));
            raw_data_fread_size = raw_data_fread_size / 4;             % nr. of int32
            rawdata_1d = double(fread(fidraw, raw_data_fread_size, 'int32'));
            frc_noise_samples_per_coil = raw_data_fread_size / 2 / nCoils;
            rawdata_1d = rawdata_1d(1:2:end) + 1i * rawdata_1d(2:2:end);
        case 3 % float32
            raw_data_fread_size = info_loc.labels.DataSize.vals(frc_noise_idx); % nr. of bytes
            nCoils = raw_data_fread_size / (info_loc.dims.nKx(1)*info_loc.sin.frc_oversample_noise_factor*8); % one complex number occupies 8 bytes
            assert(~isempty(find(info_loc.dims.nCoils == nCoils)));
            raw_data_fread_size = raw_data_fread_size / 4;             % nr. of flt32
            rawdata_1d = double(fread(fidraw, raw_data_fread_size, 'float32'));
            frc_noise_samples_per_coil = raw_data_fread_size / 2 / nCoils;
            rawdata_1d = rawdata_1d(1:2:end) + 1i * rawdata_1d(2:2:end);
        case {4,5} % coded
            error('not supported raw format');
        case 6 % coded
            nCoils = info_loc.labels.DataSize.vals(frc_noise_idx) / (info_loc.dims.nKx(1)*info_loc.sin.frc_oversample_noise_factor*8); % one complex number occupies 8 bytes
            assert(~isempty(find(info_loc.dims.nCoils == nCoils)));
            raw_data_fread_size = info_loc.labels.CodedDataSize.vals(frc_noise_idx); % nr. of bytes, 6512
            rawdatacoded = uint32(fread(fidraw, raw_data_fread_size / 4, 'uint32'));
            %multichavector = decode_rawfmt6( rawdatacoded,
            %info_loc.dims.nKx*info_loc.sin.frc_oversample_noise_factor,
            %nCoils); %info_loc.dims.nCoils ); % this line calls the
            %matlab sub function.
            multichavector = decode( double(rawdatacoded), double(info_loc.dims.nKx(1)*info_loc.sin.frc_oversample_noise_factor), double(nCoils) ); % this line calls c code to be faster.
            frc_noise_samples_per_coil = info_loc.labels.DataSize.vals(frc_noise_idx) / 4 / 2 / nCoils;
            rawdata_1d = multichavector; % double(fread(fidraw, raw_data_fread_size, 'int16'));
    end
    
    rawdata_2d = reshape(rawdata_1d, info_loc.dims.nKx(1)*info_loc.sin.frc_oversample_noise_factor, nCoils);
    
    rawdata_2d = nonlin_corr( info_loc, frc_noise_idx, rawdata_2d );
    
    % stdandard deviation, please note there is no interal to
    % exterconversion used.
    std_noise_real = std(real(rawdata_2d));
    std_noise_imag = std(imag(rawdata_2d));
    
    % correlation coefficients
    cov_noise = conj(corrcoef(rawdata_2d));
    
    % normalization factors
    noisereshape = reshape(rawdata_2d, [info_loc.dims.nKx(1), info_loc.sin.frc_oversample_noise_factor, nCoils]);
    % skip zero filling for recon resolution adjustment
    % ifftshift shift zero frequency component to center of spectrum,
    % ifft: k-> x;
    noisereshape = fftshift(ifft(ifftshift(noisereshape)));
    % combine second dimension using RMS
    temp = squeeze(sqrt(sum(noisereshape .* conj(noisereshape), 2) / info_loc.sin.frc_oversample_noise_factor));
    temp = squeeze(sqrt(sum(temp .^ 2, 1) / double(info_loc.dims.nKx(1))));
    norm_factor = max(temp) ./ temp;
    
    rawdata_2d = rawdata_2d.';
    
    
    info_loc.FRC_NOISE_DATA{k} = zeros(nCoils,frc_noise_samples_per_coil,'single');
    
    info_loc.FRC_NOISE_DATA{k} = rawdata_2d;
    info_loc.noise_level_arr{k} = std_noise_real + 1i * std_noise_imag;
    info_loc.noise_correlation_arr{k} = cov_noise;
    info_loc.noise_norm_factors{k} = norm_factor;
    
end %end-for k
  
 % Read FRC channel data, we only read FRC data for now, but no FRC
 % correction is applied to nromal imaging data. Background: FRC stands for
 % frequency response correction. Due to the existance of readout gradient,
 % spins are resonanting with difference frequencys, resulting in different
 % responses properties to the receiver, this should be corrected.
%  for k = 1:length(info_loc.idx.FRC_CH_DATA),%find the index of FRC_NOISE_DATA vectors
%      frc_ch_idx = info_loc.idx.FRC_CH_DATA(k);%one FRC_NOISE_DATA vector refers to one coil.
%      byte_offset = info_loc.fseek_offsets(frc_ch_idx);
%      fseek(fidraw, byte_offset, 'bof');   %from the start of the file
%      
%      switch info_loc.labels.RawFormat.vals(frc_ch_idx)
%          case 0 % int16
%              raw_data_fread_size = info_loc.labels.DataSize.vals(frc_ch_idx); % nr. of bytes
%              nCoils = raw_data_fread_size / (info_loc.sin.frc_resolution*4); % one complex number occupies 4 bytes
%              assert(~isempty(find(info_loc.dims.nCoils == nCoils)));
%              raw_data_fread_size = raw_data_fread_size / 2;             % nr. of int16
%              rawdata_1d = double(fread(fidraw, raw_data_fread_size, 'int16'));
%              frc_channel_data_per_coil = raw_data_fread_size / 2 / nCoils;
%              rawdata_1d = rawdata_1d(1:2:end) + 1i * rawdata_1d(2:2:end);
%          case 1 % f16
%              error('not supported raw format');
%          case 2 % int32
%              raw_data_fread_size = info_loc.labels.DataSize.vals(frc_ch_idx); % nr. of bytes
%              raw_data_fread_size = raw_data_fread_size / 4;             % nr. of int32
%              rawdata_1d = double(fread(fidraw, raw_data_fread_size, 'int32'));
%              frc_channel_data_per_coil = raw_data_fread_size / 2 / info_loc.dims.nCoils;
%          case 3 % float32
%              raw_data_fread_size = info_loc.labels.DataSize.vals(frc_ch_idx); % nr. of bytes
%              raw_data_fread_size = raw_data_fread_size / 4;             % nr. of flt32
%              rawdata_1d = double(fread(fidraw, raw_data_fread_size, 'float32'));
%              frc_channel_data_per_coil = raw_data_fread_size / 2 / info_loc.dims.nCoils;
%          case {4,5} % coded
%              error('not supported raw format');
%          case 6 % coded
%              nCoils = info_loc.labels.DataSize.vals(frc_ch_idx) / (info_loc.sin.frc_resolution*8); % one complex number occupies 8 bytes
%              assert(~isempty(find(info_loc.dims.nCoils >= nCoils)));   % note for multi-transmit channels, the frc noise receiving might be performed channel by channel seperately. So we use '>='  instead of '=='.
%              raw_data_fread_size = info_loc.labels.CodedDataSize.vals(frc_ch_idx); % nr. of bytes, 6512
%              rawdatacoded = uint32(fread(fidraw, raw_data_fread_size / 4, 'uint32'));
%              %multichavector = decode_rawfmt6( rawdatacoded, info_loc.sin.frc_resolution, nCoils);
%              multichavector = decode( double(rawdatacoded), double(info_loc.sin.frc_resolution), double(nCoils) );
%              frc_channel_data_per_coil = info_loc.labels.DataSize.vals(frc_ch_idx) / 4 / 2 / nCoils;
%              rawdata_1d = multichavector; % double(fread(fidraw, raw_data_fread_size, 'int16'));
%      end
%      
%      rawdata_2d = reshape(rawdata_1d, info_loc.sin.frc_resolution, nCoils);
%      
%      rawdata_2d = nonlin_corr( info_loc, frc_ch_idx, rawdata_2d );
%      
%      rawdata_2d = rawdata_2d.';
%      
%      info_loc.FRC_CH_DATA{k} = zeros(nCoils,frc_channel_data_per_coil,'single');
%      info_loc.FRC_CH_DATA{k} = rawdata_2d;
%  end
 
 fclose(fidraw);
 
 info = info_loc;
end

% ------------------------- Coding History --------------------------------
% - 2017-01-09, C. Zhao, chenguang.z.zhao@philips.com.
%   copied the matlab package that I believe is originally from welcheb. 
%   Started adding DDAS capabibity on top of this matlab package.
% - 2017-06-12, C. Zhao
%   Added FRC noise reading, noise correlation coefficients calculation.
% - 2017-10-26. Y. Huang
%   implement DDAS decoding in c code to accelerate data reading.
% - 2018-02-24. C. Zhao
%   comment out FRC_CH_DATA reading.
