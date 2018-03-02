function [data, info] = main_loadLABRAW( filename,varargin )
%%LOADLABRAW     Load a Philips LABRAW file
%
% [DATA,INFO] = LOADLABRAW(FILENAME)
%
%   FILENAME is a string containing a file prefix or name of the LAB
%   hexadecimal label file or RAW data file, e.g. RAW_001 or RAW_001.LAB or RAW_001.RAW
%
%   DATA is an N-dimensional array holding the raw k-space data.
%   INFO is a structure containing information of label and raw data
%  
%
% [DATA,INFO] = LOADLABRAW([])
%
%   When the passed FILENAME is not provided or is an empty array or empty
%   string.  The user chooses a file using UIGETFILE.
%
% [DATA,INFO] = LOADLABRAW(FILENAME,'OptionName1',OptionValue1,...)
%
%   Options can be passed to LOADLABRAW to control the range/pattern of
%   loaded data, verbose output, etc.  The list below shows the avialable
%   options.  Names are case-sensitive
%
%       OptionName          OptionValue       Description
%       ----------          -----------     ---------------
%       'coil'              numeric         coils
%       'kx'                numeric         k-space kx samples
%       'ky'                numeric         k-space ky rows (E1)
%       'kz'                numeric         k-space kz rows (E2)
%       'e3'                numeric         k-space 3rd encoding dim
%       'loc'               numeric         locations
%       'ec'                numeric         echoes
%       'dyn'               numeric         dynamics
%       'ph'                numeric         cardiac phases
%       'row'               numeric         rows
%       'mix'               numeric         mixes
%       'avg'               numeric         averages
%       'verbose'           logical         [ true |{false}]
%       'savememory'        logical         [{true}| false ]
%       'correct_phase'     logical         [{true}| false ]
%       'correct_dcoffset'  logical         [{true}| false ]
%       'correct_pda'       logical         [{true}| false ]
%
%       When 'savememory' is true, SINGLE precision is used instead of DOUBLE
%
%       When 'correct_phase' is true, random and measurement phase
%       corrections are applied to the data.
%       
%       When 'correct_dcoffset' is true, the DC offset for each coil
%       channel is removed using the FRC noise data.  If no FRC noise data
%       is available, no DC offset is removed. If multiple stacks of FRC
%       noise data is present, a .PDF.XML file is needed to know which
%       locations go into which stack.
%
%       When 'correct_pda' is true, the profile dependent amplification
%       is corrected using information from a .PDF.XML file with the same
%       prefix as the loaded LAB/RAW file pair.  If no .PDF.XML file is 
%       available, no pda correction is applied.
%
%   Example:
%       myfile = 'example.LAB';
%       [data,info] = loadLABRAW(myfile,'coil',[1 5],'verbose',true);
%
% [DATA,INFO] = LOADLABRAW(FILENAME,LOADOPTS)
%
%   LOADOPTS is a structure with fieldnames equal to any of the possible OptionNames.
%
%   Example:
%       loadopts.coil = [1 5];
%       loadopts.verbose = true;
%       [data,info] = loadLABRAW(myfile,loadopts);
%
%   For any dimension, values may be repeated and appear in any order.
%   Values that do not intersect with the available values for that
%   dimension will be ignored.  If the intersection of the user-defined
%   dimension values and the available dimension range has length zero, an
%   error is generated.  The order of the user-defined pattern is preserved.
%
%   Example:
%       % load a specific pattern of locations (-1 will be ignored)
%       loadopts.loc = [1 1 2 1 1 2 -1];
%       [data,info] = loadLABRAW(myfile,loadopts);
%
%Additional Note:
% INFO structure contents
%
%   The INFO structure contains all the information from the LAB file in
%   a filed names LABELS as well as other useful information to describe
%   and to work with the loaded DATA array.  The list below describes some
%   of the additional fields found within INFO
%
%   FieldName              Description
%   ---------              ------------------------------------------------
%   FILENAME               filename of the loaded data
%   LOADOPTS               structure containing the load options (see above)
%   DIMS                   structure containing the DATA dimension names and values
%   LABELS                 structure containing label names and values, ZCG: names mean field names of struct ARSRC_LABEL_STRUCT
%   LABELS_ROW_INDEX_ARRAY (see below)
%   LABEL_FIELDNAMES       names used for the labels
%   IDX                    structure of arrays of index of different label types
%   FSEEK_OFFSETS          byte offsets in the .RAW file for each data vector
%   NLABELS                # of total labels avialable in the LAB file
%   NLOADEDLABELS          # of labels loaded from the LABRAW file
%   NDATALABELS            # of labels in the returned data array (may contain repeats)
%   DATASIZE               array showing the size of the returned DATA array
%   FRC_NOISE_DATA         array of the FRC noise data
%
%   The INFO.LABELS_ROW_INDEX_ARRAY is a special array that is the same
%   size as the DATA array (minus the first two dimensions used to store
%   COIL and KX).  A given index for a given raw data vector in the DATA
%   array will return the label index number describing the details of that
%   raw data vector in the INFO.LABELS array when that same index is used
%   with the INFO.LABELS_ROW_INDEX_ARRAY.  This provides a quick way to
%   recall the details of any individual raw data vector contained within DATA.
%   If the INFO.TABLE_ROW_INDEX_ARRAY holds a ZERO for a given index, there
%   was no label from the LAB file that matched the dimension location in DATA.


% Revision History
% * 2008.11.07    initial version - welcheb
% * 2012.08.03    added dc offset and pda correction - welcheb
% * 2012.08.22    read EPI phase correction data into info structure

% Start execution time clock and initialize DATA and INFO to empty arrays
  tic
  data = [];
  info = [];

% Initialize INFO structure
% Serves to fix the display order
  info.filename = [];
  info.loadopts = [];
  info.dims = [];
  info.labels = [];
  info.labels_row_index_array = [];
  info.label_fieldnames = [];
  info.idx = [];
  info.fseek_offsets = [];
  info.nLabels = [];
  info.nLoadedLabels = [];
  info.nDataLabels = [];
  info.nNormalDataLabels = [];
  info.datasize = [];

% Allow user to select a file if input FILENAME is not provided or is empty
  if nargin < 1 || isempty(filename)
      [fn, pn] = uigetfile({'*.RAW'},'Select a RAW file');
      if fn ~= 0
          filename = sprintf('%s%s',pn,fn);
      else
          disp('LOADLABRAW cancelled');
          return;
      end
  end

% Parse the filename.
% It may be the LAB filename, RAW filename or just the filename prefix
% Instead of REGEXP, use REGEXPI which igores case
  toks = regexpi(filename,'^(.*?)(\.raw|\.lab)?$','tokens');
  prefix = toks{1}{1};
  labname = sprintf('%s.LAB',prefix);
  rawname = sprintf('%s.RAW',prefix);
  sinname = sprintf('%s.SIN',prefix);
  
  pdfxmlname = sprintf('%s.PDF.XML',prefix);
  info.filename = filename;

  % zcg: read recon parameters from SIN file.
  info.sin = step1_LoadSinFileInfo(sinname);
%read (*.lab) file and update some related parameters in the structure INFO.
  info_new = info;  
%INFO_NEW is defined as the input of the function in order to ditinguish it
%from the output of the function INFO which is the unpdated INFO_NEW
  info = step2_ReadLabData(labname,info_new);   

  
%dimensions setting and parsing the load option
  info_new = info;
info = step3_ConsistencyChecking(info_new,varargin{:});

%read the None Linerity correction data (label type equals to ARSRC_LABEL_TYPE_NON_LIN)
info_new = info;
info = step4_ReadNoneLinearityCorr( info_new, rawname);
  
%read the FRC noise data
info_new = info; 
info = step5_ReadFRC(info_new,rawname);  

%read the Echo Phase data
  info_new = info;
%   [ECHO_PHASE_DATA, info] = step4_ReadEchoPhaseData(info_new,rawname); % ZCG, note error occurs if no Echo phase data. comment out for now.

% %read the None Linerity correction data (label type equals to ARSRC_LABEL_TYPE_NON_LIN)
% info = step5_ReadNoneLinearityCorr( info_new, rawname);

%read raw kspace data
  info_new = info;
  [data, info] = step6_ReadRawData(info_new,rawname);

% If VERBOSE, display execution information
%   if info.loadopts.verbose
%       fprintf('Loaded %d of %d available normal data labels', info.nLoadedLabels, info.nNormalDataLabels);
%       tmpstr = '';
%       for k = 1:length(dimnames),
%           tmpstr = sprintf('%s, # %s: %d', tmpstr, dimnames{k}, length(info.dims.(dimnames{k})) );
%       end
%           fprintf('Data contains %d raw labels - %s', info.nDataLabels, tmpstr(3:end));
%           fprintf('Total execution time = %.3f seconds', toc);
%   end

end

% ------------------------- Coding History --------------------------------
% - 2017-01-09, C. Zhao, chenguang.z.zhao@philips.com.
%   copied the matlab package that is originally from welcheb. 
%   Started adding DDAS capabibity on top of this matlab package.

