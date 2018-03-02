function  info = step2_ReadLabData( labname, info_loc )
%%Step1_readLabData    The first step of the reading of philips rawdata
                      
%Read lab data and calculate the values of lab fieldnames (info_loc.labels)
%find indices for different label control types (info_loc.idx)
% info_loc.labels     structure containing label names and values which from .LAb file
% info_loc.idx        structure of arrays of index of different label types

% Open LAB file and read all hexadecimal labels
labfid = fopen(labname,'r');
if labfid == -1
  error('Cannot open %s for reading', labname);
end

% Read all hexadecimal labels
unparsed_labels = fread (labfid,[16 Inf], 'uint32=>uint32');                                 % ZCG, (16 X N) integers
info_loc.nLabels = size(unparsed_labels,2);
fclose(labfid);

% Parse hexadecimal labels
% Inspired by Holger Eggers' readRaw.m.  See arsrcglo1.h for more details.
% RKR - converts hexidecimal values from .LAB file into decimal label vals
info_loc.labels.DataSize.vals         = unparsed_labels(1,:);                                % ZCG, ARSRC_LABEL_STRUCT, first field, uint32

info_loc.labels.CodedDataSize.vals    = unparsed_labels(2,:);                                % ZCG, ARSRC_LABEL_STRUCT, second field, uint32


info_loc.labels.Destination.vals      = bitshift (bitand(unparsed_labels(3,:), (2^16-1)),  -0);%obtain the low 16 bits for every 32-bits matrix element in Line3
info_loc.labels.RconJobId.vals        = bitshift (bitand(unparsed_labels(3,:), (2^32-1)), -16);%obtain the high 16 bits for every 32-bits matrix element in Line3

info_loc.labels.SeqNum.vals           = bitshift (bitand(unparsed_labels(4,:), (2^16-1)),  -0);%the low 16 bits for every element in Line4
info_loc.labels.LabelType.vals        = bitshift (bitand(unparsed_labels(4,:), (2^32-1)), -16);%the high 16 bits for every element in Line4, right shift

info_loc.labels.ControlType.vals      = bitshift( bitand(unparsed_labels(5,:),  (2^8-1)),  -0);%the low 8 bits for every element in Line5
info_loc.labels.MonitoringFlag.vals   = bitshift( bitand(unparsed_labels(5,:), (2^16-1)),  -8);%from bit16 to bit9 for every element in Line5
info_loc.labels.MeasurementPhase.vals = bitshift( bitand(unparsed_labels(5,:), (2^24-1)), -16);%from bit24 to bit17 for every element in Line5
info_loc.labels.MeasurementSign.vals  = bitshift( bitand(unparsed_labels(5,:), (2^32-1)), -24);%the high 8 bits (from bit32 to bit25) for every element in Line5

info_loc.labels.GainSetting.vals      = bitshift( bitand(unparsed_labels(6,:),  (2^8-1)),  -0);%the low 8 bits for every element in Line6
info_loc.labels.RawFormat.vals           = bitshift( bitand(unparsed_labels(6,:), (2^16-1)),  -8);%from bit16 to bit9 for every element in Line6
info_loc.labels.SpurPhase_increment.vals           = bitshift (bitand(unparsed_labels(6,:), (2^32-1)), -16);%the high 16 bits for every element in Line6

info_loc.labels.ProgressCnt.vals      = bitshift (bitand(unparsed_labels(7,:), (2^16-1)),  -0);%the low 16 bits for every element in Line7
info_loc.labels.Mix.vals              = bitshift (bitand(unparsed_labels(7,:), (2^32-1)), -16);%the high 16 bits for every element in Line7

info_loc.labels.Dynamic.vals          = bitshift (bitand(unparsed_labels(8,:), (2^16-1)),  -0);%the low 16 bits for every element in Line8
info_loc.labels.CardiacPhase.vals     = bitshift (bitand(unparsed_labels(8,:), (2^32-1)), -16);%the high 16 bits for every element in Line8

info_loc.labels.Echo.vals             = bitshift (bitand(unparsed_labels(9,:), (2^16-1)),  -0);%the low 16 bits for every element in Line9
info_loc.labels.Location.vals         = bitshift (bitand(unparsed_labels(9,:), (2^32-1)), -16);%the high 16 bits for every element in Line9

info_loc.labels.Row.vals              = bitshift (bitand(unparsed_labels(10,:), (2^16-1)),  -0);%the low 16 bits for every element in Line10
info_loc.labels.ExtraAtrr.vals        = bitshift (bitand(unparsed_labels(10,:), (2^32-1)), -16);%the high 16 bits for every element in Line10

info_loc.labels.Measurement.vals      = bitshift (bitand(unparsed_labels(11,:), (2^16-1)),  -0);%the low 16 bits for every element in Line11
info_loc.labels.E1.vals               = bitshift (bitand(unparsed_labels(11,:), (2^32-1)), -16);%the high 16 bits for every element in Line11

info_loc.labels.E2.vals               = bitshift (bitand(unparsed_labels(12,:), (2^16-1)),  -0);%the low 16 bits for every element in Line12
info_loc.labels.E3.vals               = bitshift (bitand(unparsed_labels(12,:), (2^32-1)), -16);%the high 16 bits for every element in Line12

info_loc.labels.RfEcho.vals           = bitshift (bitand(unparsed_labels(13,:), (2^16-1)),  -0);%the low 16 bits for every element in Line13
info_loc.labels.GradEcho.vals         = bitshift (bitand(unparsed_labels(13,:), (2^32-1)), -16);%the high 16 bits for every element in Line13

info_loc.labels.EncTime.vals          = bitshift (bitand(unparsed_labels(14,:), (2^16-1)),  -0);%the low 16 bits for every element in Line14
info_loc.labels.RandomPhase.vals      = uint16(bitshift (bitand(unparsed_labels(14,:), (2^32-1)), -16));%the high 16 bits for every element in Line14

info_loc.labels.RRInterval.vals       = bitshift (bitand(unparsed_labels(15,:), (2^16-1)),  -0);%the low 16 bits for every element in Line15
info_loc.labels.RTopOffset.vals       = bitshift (bitand(unparsed_labels(15,:), (2^32-1)), -16);%the high 16 bits for every element in Line15

info_loc.labels.ChannelsActive.vals   = unparsed_labels(16,:);

clear unparsed_labels;

% Find unique values of each label field
info_loc.label_fieldnames = fieldnames(info_loc.labels);
for k = 1:length(info_loc.label_fieldnames)
  info_loc.labels.(info_loc.label_fieldnames{k}).uniq = unique( info_loc.labels.(info_loc.label_fieldnames{k}).vals );  % find the unique value for the 33 fieldnames in the LAB. ( ZCG: should be 32? )
end

% Calculate fseek offsets
info_loc.fseek_offsets = zeros(info_loc.nLabels,1);
info_loc.fseek_offsets(1)=512; % add mysterious 512 byte offset to begin reading file
for k = 2:info_loc.nLabels
    % ZCG, fseek offset depends on rawformat
      switch info_loc.labels.RawFormat.vals(k-1)
          case {0, 1, 2, 3, 5}
              info_loc.fseek_offsets(k) = info_loc.fseek_offsets(k-1)+ info_loc.labels.DataSize.vals(k-1) ;
          case {4, 6}
              info_loc.fseek_offsets(k) = info_loc.fseek_offsets(k-1)+ info_loc.labels.CodedDataSize.vals(k-1) ;
      end
  % info_loc.fseek_offsets(k) = info_loc.fseek_offsets(k-1)+ info_loc.labels.DataSize.vals(k-1) ; % ZCG, should take care of raw_format.
  %address of the next vecotr in the address point. it equals: address of last vector + datasize of last vector
end
info_loc.idx.no_data = find(info_loc.labels.DataSize.vals == 0);  %find the index of the vector whose datasize is zero
info_loc.fseek_offsets(info_loc.idx.no_data) = -1;                %if the datasize is zero, then the offset is set to be -1

% Find indices of different label control types
% See arsrcglo1.h for more details.
standard_labels = info_loc.labels.LabelType.vals==32513;      %find the vectors whose labeltype value equals to standard value 32513, their indexes are recorded in STANDARD_LABELS 32513=2^15-(2^8-1), 0x7F01
info_loc.idx.NORMAL_DATA         = find(info_loc.labels.ControlType.vals== 0 & standard_labels); %find the vectors whose controltype =0 & labetype=32513,they are the positions of NORMAL_DATA in the LAB matrix
info_loc.idx.DC_OFFSET_DATA      = find(info_loc.labels.ControlType.vals== 1 & standard_labels); %find the vectors whose controltype =1 & labetype=32513,they are the positions of DC_OFFSET_DATA in the LAB matrix
info_loc.idx.JUNK_DATA           = find(info_loc.labels.ControlType.vals== 2 & standard_labels); %find the vectors whose controltype =2 & labetype=32513,they are the positions of JUNK_DATA in the LAB matrix
info_loc.idx.ECHO_PHASE_DATA     = find(info_loc.labels.ControlType.vals== 3 & standard_labels); %find the vectors whose controltype =3 & labetype=32513,they are the positions of ECHO_PHASE_DATA in the LAB matrix
info_loc.idx.NO_DATA             = find(info_loc.labels.ControlType.vals== 4 & standard_labels); %find the vectors whose controltype =4 & labetype=32513,they are the positions of NO_DATA in the LAB matrix
info_loc.idx.NEXT_PHASE          = find(info_loc.labels.ControlType.vals== 5 & standard_labels); %find the vectors whose controltype =5 & labetype=32513,they are the positions of NEXT_PHASE in the LAB matrix
info_loc.idx.SUSPEND             = find(info_loc.labels.ControlType.vals== 6 & standard_labels); %find the vectors whose controltype =6 & labetype=32513,they are the positions of SUSPEND in the LAB matrix
info_loc.idx.RESUME              = find(info_loc.labels.ControlType.vals== 7 & standard_labels); %find the vectors whose controltype =7 & labetype=32513,they are the positions of RESUME in the LAB matrix
info_loc.idx.TOTAL_END           = find(info_loc.labels.ControlType.vals== 8 & standard_labels); %find the vectors whose controltype =8 & labetype=32513,they are the positions of TOTAL_END in the LAB matrix
info_loc.idx.INVALIDATION        = find(info_loc.labels.ControlType.vals== 9 & standard_labels); %find the vectors whose controltype =9 & labetype=32513,they are the positions of INVALIDATION in the LAB matrix
info_loc.idx.TYPE_NR_END         = find(info_loc.labels.ControlType.vals==10 & standard_labels); %find the vectors whose controltype =10 & labetype=32513,they are the positions of TYPE_NR_END in the LAB matrix
info_loc.idx.VALIDATION          = find(info_loc.labels.ControlType.vals==11 & standard_labels); %find the vectors whose controltype =11 & labetype=32513,they are the positions of VALIDATION in the LAB matrix
info_loc.idx.NO_OPERATION        = find(info_loc.labels.ControlType.vals==12 & standard_labels); %find the vectors whose controltype =12 & labetype=32513,they are the positions of NO_OPERATION in the LAB matrix
info_loc.idx.DYN_SCAN_INFO       = find(info_loc.labels.ControlType.vals==13 & standard_labels); %find the vectors whose controltype =13 & labetype=32513,they are the positions of DYN_SCAN_INFO in the LAB matrix
info_loc.idx.SELECTIVE_END       = find(info_loc.labels.ControlType.vals==14 & standard_labels); %find the vectors whose controltype =14 & labetype=32513,they are the positions of SELECTIVE_END in the LAB matrix
info_loc.idx.FRC_CH_DATA         = find(info_loc.labels.ControlType.vals==15 & standard_labels); %find the vectors whose controltype =15 & labetype=32513,they are the positions of FRC_CH_DATA in the LAB matrix
info_loc.idx.FRC_NOISE_DATA      = find(info_loc.labels.ControlType.vals==16 & standard_labels); %find the vectors whose controltype =16 & labetype=32513,they are the positions of FRC_NOISE_DATA in the LAB matrix
info_loc.idx.REFERENCE_DATA      = find(info_loc.labels.ControlType.vals==17 & standard_labels); %find the vectors whose controltype =17 & labetype=32513,they are the positions of REFERENCE_DATA in the LAB matrix
info_loc.idx.DC_FIXED_DATA       = find(info_loc.labels.ControlType.vals==18 & standard_labels); %find the vectors whose controltype =18 & labetype=32513,they are the positions of DC_FIXED_DATA in the LAB matrix
info_loc.idx.DNAVIGATOR_DATA     = find(info_loc.labels.ControlType.vals==19 & standard_labels); %find the vectors whose controltype =19 & labetype=32513,they are the positions of DNAVIGATOR_DATA in the LAB matrix
info_loc.idx.FLUSH               = find(info_loc.labels.ControlType.vals==20 & standard_labels); %find the vectors whose controltype =20 & labetype=32513,they are the positions of FLUSH in the LAB matrix
info_loc.idx.RECON_END           = find(info_loc.labels.ControlType.vals==21 & standard_labels); %find the vectors whose controltype =21 & labetype=32513,they are the positions of RECON_END in the LAB matrix
info_loc.idx.IMAGE_STATUS        = find(info_loc.labels.ControlType.vals==22 & standard_labels); %find the vectors whose controltype =22 & labetype=32513,they are the positions of IMAGE_STATUS in the LAB matrix
info_loc.idx.TRACKING            = find(info_loc.labels.ControlType.vals==23 & standard_labels); %find the vectors whose controltype =23 & labetype=32513,they are the positions of TRACKING in the LAB matrix
info_loc.idx.FLUOROSCOPY_TOGGLE  = find(info_loc.labels.ControlType.vals==24 & standard_labels); %find the vectors whose controltype =24 & labetype=32513,they are the positions of FLUROSCOPY in the LAB matrix
info_loc.idx.REJECTED_DATA       = find(info_loc.labels.ControlType.vals==25 & standard_labels); %find the vectors whose controltype =25 & labetype=32513,they are the positions of REJECT_DATA in the LAB matrix
info_loc.idx.PROGRESS_INFO       = find(info_loc.labels.ControlType.vals==26 & standard_labels); %find the vectors whose controltype =26 & labetype=32513,they are the positions of PROGRESS_INFO in the LAB matrix
info_loc.idx.END_PREP_PHASE      = find(info_loc.labels.ControlType.vals==27 & standard_labels); %find the vectors whose controltype =27 & labetype=32513,they are the positions of END_PREP_PHASE in the LAB matrix
info_loc.idx.CHANNEL_DEFINITION  = find(info_loc.labels.ControlType.vals==28 & standard_labels); %find the vectors whose controltype =28 & labetype=32513,they are the positions of CHANNEL_DEDINITION in the LAB matrix
info_loc.idx.START_SCAN_INFO     = find(info_loc.labels.ControlType.vals==29 & standard_labels); %find the vectors whose controltype =29 & labetype=32513,they are the positions of START_SCAN_INFO in the LAB matrix
info_loc.idx.DYN_PH_NAV_DATA     = find(info_loc.labels.ControlType.vals==30 & standard_labels); %find the vectors whose controltype =30 & labetype=32513,they are the positions of DYN_PH_NAV_DATA in the LAB matrix

% find label type ARSRC_LABEL_TYPE_NON_LIN for non linearity correction.
% note there are a few label types, then in standard label type, there are
% all kinds of control types.
non_lin_labels = info_loc.labels.LabelType.vals==32517; % 0x7F05
info_loc.idx.ARSRC_LABEL_TYPE_NON_LIN = find(non_lin_labels);

% number of total labels
info_loc.nLabels = length(info_loc.labels.DataSize.vals); %assignment again for INFO.NLABELS

% Calculate number of standard, normal data labels
info_loc.nNormalDataLabels = length(info_loc.idx.NORMAL_DATA);  %the number of NORMAL_DATA vectors

% raw format
norm_idx_first = info_loc.idx.NORMAL_DATA(1);
info_loc.raw_format = info_loc.labels.RawFormat.vals(norm_idx_first);

info = info_loc;

end

% ------------------------- Coding History --------------------------------
% - 2017-01-09, C. Zhao, chenguang.z.zhao@philips.com.
%   copied the matlab package that is originally from welcheb. 
%   Started adding DDAS capabibity on top of this matlab package.

