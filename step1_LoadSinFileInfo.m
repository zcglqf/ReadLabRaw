function info = step1_LoadSinFileInfo(sinname, varargin)
%//////////////////////////////////////////////////////////////////////////
% Function: read header information from Philips MR *.SIN file
% 
% parameters:
%      sinname, full path name of the *.sin file.
% 
% returns:
%      recon parameters in a structure.
%
% syntax:
%      info = floadphilipsparhdrinfo(sinname);
%      info = floadphilipsparhdrinfo(sinname, 'verbose', true);
%
% remarks:
%      Recon parameter are read one by one, instead of all at once. This
%      way to choose most important parmeters to load and to ease the
%      mainteniance.
% Documentation:
% 2017-01-20, C. Zhao, chenguang.z.zhao@philips.com
% Philips Healthcare Suzhou
%//////////////////////////////////////////////////////////////////////////

info = [];

info.dims.nStacks        = 0;  % scalar
info.dims.nCoils         = []; % vector, dependent of stack
info.dims.nKx            = []; % vector, dependent of mix and echo
info.dims.nKy            = []; % vector, dependent of mix and echo
info.dims.nKz            = []; % vector, dependent of mix and echo
info.dims.nE3            = []; % vector, dependent of mix and echo
info.dims.nLocations     = []; % vector, dependent of mix 
info.dims.nEchoes        = []; % vector, dependent of mix 
info.dims.nDynamics      = []; % vector, dependent of mix
info.dims.nCardiacPhases = []; % vector, dependent of mix
info.dims.nRows          = []; % vector, dependent of mix
info.dims.nMixes         = 0;  % scalar
info.dims.nMeasurements  = []; % vector, dependent of mix
info.dims.nExtraAttrs    = 0;  % vector, dependent of mix

fid = fopen(sinname, 'r');
if fid == -1
    fprintf(2, 'in function ''step6_LoadSinFileInfo(...)'', can''t open file!\n');
    return;
end

% - load full text into a string
str = fread(fid, '*char')';
fclose(fid);

p = inputParser;
p.StructExpand = true;
p.CaseSensitive = false;
p.KeepUnmatched = false; % throw an error for unmatched inputs
p.addParamValue('verbose', false, @islogical);
p.parse(varargin{:});
verbose = '';
if p.Results.verbose == true
     verbose = sprintf('file %s has the following scan/recon parameters:', sinname);
     disp(verbose);
end
%- Note      : in the following comments, character '|' is used as a
%-     seperator to illustrate the structure of the expression. It is NOT
%-     contained in the expression.

%- number of stacks
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|nr_stacks|space(n)|colon|space(n)|number 
%- expample           :         |    00    |        |    00    |        |    00    |  :  |        |nr_stacks|        |  :  |        |  5
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |nr_stacks|  \s*   |  :  |   \s*  | (\d+)
expn = '\s\d\d\s\d\d\s\d\d\:\snr_stacks\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.dims.nStacks = 1;
else
    info.dims.nStacks = str2num(tokens{1}{1});
end
if p.Results.verbose == true
     verbose = sprintf('%20s:%d', 'Stacks', info.dims.nStacks);
     disp(verbose);     
end

%- number of mixes
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|nr_mixes|space(n)|colon|space(n)|number 
%- expample           :         |    01    |        |    00    |        |    00    |  :  |        |nr_mixes|        |  :  |        |  1
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |nr_mixes|  \s*   |  :  |   \s*  | (\d+)
expn = '\s\d\d\s\d\d\s\d\d\:\snr_mixes\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.dims.nMixes = 1;
else
    info.dims.nMixes = str2num(tokens{1}{1}); %#ok<*ST2NM>
end
if p.Results.verbose == true
     verbose = sprintf('%20s:%d', 'Mixes', info.dims.nMixes);
     disp(verbose);     
end

%- number of dynamics
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|nr_dynamic_scans|space(n)|colon|space(n)|number 
%- expample           :         |    01    |        |    00    |        |    00    |  :  |        |nr_dynamic_scans|        |  :  |        |  1
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |nr_dynamic_scans|  \s*   |  :  |   \s*  | (\d+)
info.dims.nDynamics = zeros(1, info.dims.nMixes);
expn = '\s(\d\d)\s\d\d\s\d\d\:\snr_dynamic_scans\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.dims.nDynamics = ones(1, info.dims.nMixes);
else
    for itok = 1 : length(tokens)
       mixno = str2num(tokens{1, itok}{1,1});
       assert(mixno <= info.dims.nMixes, 'mix no read from nr_dynamic_scans lines MUST be smaller or equal to number of mixes!');
       nodyn = str2num(tokens{1, itok}{1,2});
       info.dims.nDynamics(mixno) = nodyn;
    end       
end
if p.Results.verbose == true
     verbose = sprintf('%20s:%s', 'Dynamics', num2str(info.dims.nDynamics));
     disp(verbose);     
end

%- number of echos
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|nr_echoes|space(n)|colon|space(n)|number 
%- expample           :         |    01    |        |    00    |        |    00    |  :  |        |nr_echoes|        |  :  |        |  1
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |nr_echoes|  \s*   |  :  |   \s*  | (\d+)
info.dims.nEchoes = zeros(1, info.dims.nMixes);
expn = '\s(\d\d)\s\d\d\s\d\d\:\snr_echoes\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.dims.nEchoes = ones(1, info.dims.nMixes);
else
    for itok = 1 : length(tokens)
       mixno = str2num(tokens{1, itok}{1,1});
       assert(mixno <= info.dims.nMixes, 'mix no read from nr_echoes lines MUST be smaller or equal to number of mixes!');
       noeco = str2num(tokens{1, itok}{1,2});
       info.dims.nEchoes(mixno) = noeco;
    end        
end
if p.Results.verbose == true
     verbose = sprintf('%20s:%s', 'Echos', num2str(info.dims.nEchoes));
     disp(verbose);     
end
%- number of locations
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|nr_locations|space(n)|colon|space(n)|number 
%- expample           :         |    01    |        |    00    |        |    00    |  :  |        |nr_locations|        |  :  |        |  1
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |nr_locations|  \s*   |  :  |   \s*  | (\d+)
info.dims.nLocations = zeros(1, info.dims.nMixes);
expn = '\s(\d\d)\s\d\d\s\d\d\:\snr_locations\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.dims.nLocations = ones(1, info.dims.nMixes);
else
    for itok = 1 : length(tokens)
       mixno = str2num(tokens{1, itok}{1,1});
       assert(mixno <= info.dims.nMixes, 'mix no read from nr_locations lines MUST be smaller or equal to number of mixes!');
       nolca = str2num(tokens{1, itok}{1,2});
       info.dims.nLocations(mixno) = nolca;
    end
end
if p.Results.verbose == true
     verbose = sprintf('%20s:%s', 'Locations', num2str(info.dims.nLocations));
     disp(verbose);     
end

%- number of cardiac_phases
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|nr_cardiac_phases|space(n)|colon|space(n)|number 
%- expample           :         |    01    |        |    00    |        |    00    |  :  |        |nr_cardiac_phases|        |  :  |        |  1
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |nr_cardiac_phases|  \s*   |  :  |   \s*  | (\d+)
info.dims.nCardiacPhases = zeros(1, info.dims.nMixes);
expn = '\s(\d\d)\s\d\d\s\d\d\:\snr_cardiac_phases\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.dims.nCardiacPhases = ones(1, info.dims.nMixes);
else
    for itok = 1 : length(tokens)
       mixno = str2num(tokens{1, itok}{1,1});
       assert(mixno <= info.dims.nMixes, 'mix no read from nr_cardiac_phases lines MUST be smaller or equal to number of mixes!');
       nocar = str2num(tokens{1, itok}{1,2});
       info.dims.nCardiacPhases(mixno) = nocar;
    end        
end

%- number of rows
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|nr_rows|space(n)|colon|space(n)|number 
%- expample           :         |    01    |        |    00    |        |    00    |  :  |        |nr_rows|        |  :  |        |  1
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |nr_rows|  \s*   |  :  |   \s*  | (\d+)
info.dims.nRows = zeros(1, info.dims.nMixes);
expn = '\s(\d\d)\s\d\d\s\d\d\:\snr_rows\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.dims.nRows = ones(1, info.dims.nMixes);
else
    for itok = 1 : length(tokens)
       mixno = str2num(tokens{1, itok}{1,1});
       assert(mixno <= info.dims.nMixes, 'mix no read from nr_rows lines MUST be smaller or equal to number of mixes!');
       norow = str2num(tokens{1, itok}{1,2});
       info.dims.nRows(mixno) = norow;
    end         
end

%- number of extra_attr
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|nr_extra_attr_values|space(n)|colon|space(n)|number 
%- expample           :         |    01    |        |    00    |        |    00    |  :  |        |nr_extra_attr_values|        |  :  |        |  1
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |nr_extra_attr_values|  \s*   |  :  |   \s*  | (\d+)
info.dims.nExtraAttrs = zeros(1, info.dims.nMixes);
expn = '\s(\d\d)\s\d\d\s\d\d\:\snr_extra_attr_values\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.dims.nExtraAttrs = ones(1, info.dims.nMixes);
else
    for itok = 1 : length(tokens)
       mixno = str2num(tokens{1, itok}{1,1});
       assert(mixno <= info.dims.nMixes, 'mix no read from nr_extra_attr_values lines MUST be smaller or equal to number of mixes!');
       noexa = str2num(tokens{1, itok}{1,2});
       info.dims.nExtraAttrs(mixno) = noexa;
    end
end
if p.Results.verbose == true
     verbose = sprintf('%20s:%s', 'ExtraAttributes', num2str(info.dims.nExtraAttrs));
     disp(verbose);     
end

%- number of measurements
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|nr_measurements|space(n)|colon|space(n)|number 
%- expample           :         |    01    |        |    00    |        |    00    |  :  |        |nr_measurements|        |  :  |        |  1
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |nr_measurements|  \s*   |  :  |   \s*  | (\d+)
info.dims.nMeasurements = zeros(1, info.dims.nMixes);
expn = '\s(\d\d)\s\d\d\s\d\d\:\snr_measurements\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.dims.nMeasurements = ones(1, info.dims.nMixes);
else
    for itok = 1 : length(tokens)
       mixno = str2num(tokens{1, itok}{1,1});
       assert(mixno <= info.dims.nMixes, 'mix no read from nr_measurements lines MUST be smaller or equal to number of mixes!');
       nomea = str2num(tokens{1, itok}{1,2});
       info.dims.nMeasurements(mixno) = nomea;
    end
end
if p.Results.verbose == true
     verbose = sprintf('%20s:%s', 'Measurements', num2str(info.dims.nMeasurements));
     disp(verbose);     
end

%- 00 00 00: relative_fear_bandwidth      :       0.1000
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|nr_dynamic_scans|space(n)|colon|space(n)|number 
%- expample           :         |    01    |        |    00    |        |    00    |  :  |        |nr_dynamic_scans|        |  :  |        |  1
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |nr_dynamic_scans|  \s*   |  :  |   \s*  | (\d+)
expn = '\s\d\d\s\d\d\s\d\d\:\srelative_fear_bandwidth\s*:\s*(\d+\.?\d*)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.relative_fear_bandwidth = 0.0;
else
    info.relative_fear_bandwidth = str2num(tokens{1}{1}); %#ok<*ST2NM>
end
if p.Results.verbose == true
     verbose = sprintf('%20s:%f', 'relative_fear_bandwidth', info.relative_fear_bandwidth);
     disp(verbose);     
end

%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|frc_oversample_noise_factor|space(n)|colon|space(n)number 
%- expample           :         |    00    |        |    00    |        |    00    |  :  |        |frc_oversample_noise_factor|        |  :  |         44 
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d   |  :  |   \s   |frc_oversample_noise_factor|  \s*   |  :  |       (\d+) 
expn = '\s\d\d\s\d\d\s\d\d\:\sfrc_oversample_noise_factor\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.frc_oversample_noise_factor = 1;
else
    info.frc_oversample_noise_factor = str2num(tokens{1}{1}); %#ok<*ST2NM>
end
if p.Results.verbose == true
     verbose = sprintf('%20s:%f', 'frc_oversample_noise_factor', info.frc_oversample_noise_factor);
     disp(verbose);     
end

%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|frc_resolution|space(n)|colon|space(n)number 
%- expample           :         |    00    |        |    00    |        |    00    |  :  |        |frc_resolution|        |  :  |         2048 
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d   |  :  |   \s   |frc_resolution|  \s*   |  :  |       (\d+) 
expn = '\s\d\d\s\d\d\s\d\d\:\sfrc_resolution\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.frc_resolution = 1;
else
    info.frc_resolution = str2num(tokens{1}{1}); %#ok<*ST2NM>
end
if p.Results.verbose == true
     verbose = sprintf('%20s:%f', 'frc_resolution', info.frc_resolution);
     disp(verbose);     
end

%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|enable_pda|space(n)|colon|space(n)number 
%- expample           :         |    00    |        |    00    |        |    00    |  :  |        |enable_pda|        |  :  |         44 
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d   |  :  |   \s   |enable_pda|  \s*   |  :  |       (\d+) 
expn = '\s\d\d\s\d\d\s\d\d\:\senable_pda\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.enable_pda = 0;
else
    info.enable_pda = str2num(tokens{1}{1}); %#ok<*ST2NM>
end
if p.Results.verbose == true
     verbose = sprintf('%20s:%d', 'enable_pda', info.enable_pda);
     disp(verbose);     
end


%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|enable_dc_offset_corr|space(n)|colon|space(n)number 
%- expample           :         |    00    |        |    00    |        |    00    |  :  |        |enable_dc_offset_corr|        |  :  |         44 
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d   |  :  |   \s   |enable_dc_offset_corr|  \s*   |  :  |       (\d+) 
expn = '\s\d\d\s\d\d\s\d\d\:\senable_dc_offset_corr\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.enable_dc_offset_corr = 0;
else
    info.enable_dc_offset_corr = str2num(tokens{1}{1}); %#ok<*ST2NM>
end
if p.Results.verbose == true
     verbose = sprintf('%20s:%d', 'enable_dc_offset_corr', info.enable_dc_offset_corr);
     disp(verbose);     
end

%-  01 00 00: nr_locs_per_stack_arr        :            3            3            3
%-  01 00 00: loc_nr_begin_per_stack_arr   :            0            3            6
%-  01 00 00: loc_nr_incr_per_stack_arr    :            1            1            1
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|nr_locs_per_stack_arr|space(n)|colon|space(n)number|space(n)|number|........ 
%- expample           :         |    00    |        |    00    |        |    00    |  :  |        |nr_locs_per_stack_arr|        |  :  |            3            3            3 
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |nr_locs_per_stack_arr|  \s*   |  :  |       (\s*\d+)+ 
info.dims.nr_locs_per_stack_arr = zeros(1, info.dims.nStacks);
if(info.dims.nStacks > 1)
    expn = '\s\d\d\s\d\d\s\d\d\:\snr_locs_per_stack_arr\s*:(\s*\d+)+[\r\n]';  % (\s*\d+)+ is a token expression - space followed by number, at least once. [\r\n] either \r or \n - return or new line
    tokens = regexp(str, expn, 'tokens');
    if isempty(tokens)
        info.dims.nr_locs_per_stack_arr = ones(1, info.dims.nStacks);
    else
        info.dims.nr_locs_per_stack_arr = str2num(tokens{1}{1});
        for itok = 2 : length(tokens)
            oneline = str2num(tokens{itok}{1});
            info.dims.nr_locs_per_stack_arr = horzcat(info.dims.nr_locs_per_stack_arr, oneline);                % may have more than one line, Concatenate lines.
        end
    end
    % consistency checking
    assert(info.dims.nStacks == length(info.dims.nr_locs_per_stack_arr), 'number of Stacks and size of nr_locs_per_stack_arr MUST equal');
    assert(sum(info.dims.nr_locs_per_stack_arr) == info.dims.nLocations(1), 'Total number of Locations from all of the Stack MUST be equal to value of Location parameters');
elseif(info.dims.nStacks == 1)
    info.dims.nr_locs_per_stack_arr = info.dims.nLocations;
end

info.dims.loc_nr_begin_per_stack_arr = zeros(1, info.dims.nStacks);
expn = '\s\d\d\s\d\d\s\d\d\:\sloc_nr_begin_per_stack_arr\s*:(\s*\d+)+[\r\n]';  % (\s*\d+)+ is a token expression - space followed by number, at least once. [\r\n] either \r or \n - return or new line 
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.dims.loc_nr_begin_per_stack_arr = zeros(1, info.dims.nStacks);        % note: location number starts from 0
else
    info.dims.loc_nr_begin_per_stack_arr = str2num(tokens{1}{1});            
    for itok = 2 : length(tokens)
       oneline = str2num(tokens{itok}{1});
       info.dims.loc_nr_begin_per_stack_arr = horzcat(info.dims.loc_nr_begin_per_stack_arr, oneline);                % may have more than one line, Concatenate lines.
    end    
end
% consistency checking
assert(info.dims.nStacks == length(info.dims.loc_nr_begin_per_stack_arr), 'number of Stacks and size of loc_nr_begin_per_stack_arr MUST equal');

info.dims.loc_nr_incr_per_stack_arr = zeros(1, info.dims.nStacks);
expn = '\s\d\d\s\d\d\s\d\d\:\sloc_nr_incr_per_stack_arr\s*:(\s*\d+)+[\r\n]';  % (\s*\d+)+ is a token expression - space followed by number, at least once. [\r\n] either \r or \n - return or new line 
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.dims.loc_nr_incr_per_stack_arr = ones(1, info.dims.nStacks);
else
    info.dims.loc_nr_incr_per_stack_arr = str2num(tokens{1}{1});            
    for itok = 2 : length(tokens)
       oneline = str2num(tokens{itok}{1});
       info.dims.loc_nr_incr_per_stack_arr = horzcat(info.dims.loc_nr_incr_per_stack_arr, oneline);                % may have more than one line, Concatenate lines.
    end    
end
% consistency checking
assert(info.dims.nStacks == length(info.dims.loc_nr_incr_per_stack_arr), 'number of Stacks and size of loc_nr_incr_per_stack_arr MUST equal');

if p.Results.verbose == true
    for istk = 1 : info.dims.nStacks
        fprintf('%20s %d has %d locations, loc numbers are:\r', 'Stack', istk, info.dims.nr_locs_per_stack_arr(istk) );
        fprintf('%20d\r', info.dims.loc_nr_begin_per_stack_arr(istk) + (0 : info.dims.nr_locs_per_stack_arr(istk)-1)*info.dims.loc_nr_incr_per_stack_arr(istk));
    end    
end

% derive location to stack number
if info.dims.nStacks == 1
    info.dims.loc_to_stack = zeros(1, info.dims.nLocations);
elseif info.dims.nStacks > 1
    info.dims.loc_to_stack = zeros(1, info.dims.nLocations);
    for istk = 1 : info.dims.nStacks
        idx_loc = info.dims.loc_nr_begin_per_stack_arr(istk) + (0 : info.dims.nr_locs_per_stack_arr(istk)-1) * info.dims.loc_nr_incr_per_stack_arr(istk) + 1;
        info.dims.loc_to_stack(idx_loc) = istk - 1;
    end
end
if p.Results.verbose == true
        fprintf('stack number of each location: %20d\r', info.dims.loc_to_stack);
end

%- number of channels ( of each stack)
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|nr_measured_channels|space(n)|colon|space(n)number|space(n)|number|........ 
%- expample           :         |    00    |        |    00    |        |    00    |  :  |        |nr_measured_channels|        |  :  |    1    5    16    16 
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |nr_measured_channels|  \s*   |  :  |       (\s*\d+)+ 
expn = '\s\d\d\s\d\d\s\d\d\:\snr_measured_channels\s*:(\s*\d+)+[\r\n]';  % (\s*\d+)+ is a token expression - space followed by number, at least once. [\r\n] either \r or \n - return or new line 
tokens = regexp(str, expn, 'tokens');
info.dims.nCoils = str2num(tokens{1}{1});                                % parameter nr_measured_channels is garanteed to be existing, no empty checking needed.
for itok = 2 : length(tokens)
   oneline = str2num(tokens{itok}{1});
   info.dims.nCoils = horzcat(info.dims.nCoils, oneline);                % may have more than one line, Concatenate lines.
end
% consistency checking
assert(info.dims.nStacks == length(info.dims.nCoils), 'number of Stacks and number of modes MUST equal');

%- channel names. To access to i-th element, use channel_names{i}{1};
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|channel_names|space(n)|colon|space(1)|strings 
%- expample           :         |    00    |        |    00    |        |    00    |  :  |        |channel_names|        |  :  |        | _ODU_8_DCC0/MSK_S_8_ACI_8.E1 
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |channel_names|  \s*   |  :  |   \s   |  (\S+) 
expn = '\s\d\d\s\d\d\s\d\d\:\schannel_names\s*:\s(\S+)[\r\n]';  % (\S+)+ is a token expression - string of more than one non-white-space character. [\r\n] either \r or \n - return or new line 
tokens = regexp(str, expn, 'tokens');
info.dims.channel_names = tokens;

% receiver nr for each channel name.
%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits|colon|space(1)|channel_names|space(n)|colon|space(1)|strings 
%  01 00 00: receiver_nrs                 :            0            1            2            3
%  05 00 00: receiver_nrs                 :            4            5            6            7
%  09 00 00: receiver_nrs                 :            4
expn = '\s\d\d\s\d\d\s\d\d\:\sreceiver_nrs\s*:(\s*\d+)+[\r\n]';  % (\s*\d+)+ is a token expression - space followed by number, at least once. [\r\n] either \r or \n - return or new line 
tokens = regexp(str, expn, 'tokens');
receiver_nrs = [];
for itok = 1 : length(tokens)
   receiver_nrs = horzcat(receiver_nrs, str2num(tokens{1, itok}{1,1}));
   %assert(stackno <= info.dims.nStacks, 'stack no read from measured_channels lines MUST be smaller or equal to number of stacks!');
end
info.dims.receiver_nrs = receiver_nrs;
assert(isempty(receiver_nrs) || length(receiver_nrs) == length(info.dims.channel_names), 'number of channels and number of receivers must equal'); % note: receiver_nrs can be empty, it might be available only on DDAS.

% notes:
% stack -> measured_channels_of_stacks -> channel name 
%                                         external channel number -> receiver_nrs -> dc_fixed_arr


%- expression semantic: space(1)|two digits|space(1)|two digits|space(1)|two digits(stack no)|colon|space(1)|measured_channels|space(n)|colon|space(n)number|space(n)|number|........ 
%- expample           :         |    00    |        |    00    |        |    00              |  :  |        |measured_channels|        |  :  |    1            2            3            4 
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   (\d\d\)          |  :  |   \s   |measured_channels|  \s*   |  :  |       (\s*\d+)+ 
expn = '\s\d\d\s\d\d\s(\d\d)\:\smeasured_channels\s*:(\s*\d+)+[\r\n]';  % (\s*\d+)+ is a token expression - space followed by number, at least once. [\r\n] either \r or \n - return or new line 
tokens = regexp(str, expn, 'tokens');
measured_channels_of_stacks = cell(1, info.dims.nStacks);
for itok = 1 : length(tokens)
   stackno = str2num(tokens{1, itok}{1,1});
   assert(stackno <= info.dims.nStacks, 'stack no read from measured_channels lines MUST be smaller or equal to number of stacks!');
   channno = str2num(tokens{1, itok}{1,2});
   measured_channels_of_stacks{stackno} = horzcat(measured_channels_of_stacks{stackno}, channno);                % may have more than one line, Concatenate lines.
end
info.dims.measured_channels_of_stacks = measured_channels_of_stacks;
% consistency checking
% assert(info.dims.nStacks == length(info.dims.nCoils), 'number of Stacks and number of modes MUST equal');
for istk = 1 : length(info.dims.measured_channels_of_stacks)
    errmsg = sprintf('number of receiving channels of stack %d MUST equal to %d', istk, info.dims.nCoils(istk));
    assert(length(info.dims.measured_channels_of_stacks{istk}) == info.dims.nCoils(istk), errmsg);
end

if p.Results.verbose == true
    for istk = 1 : info.dims.nStacks
        fprintf('%20s %d has %d receiving channels, the channel names are:\r', 'Stack', istk, info.dims.nCoils(istk) );
        chaidxarr = info.dims.measured_channels_of_stacks{istk};     % absolute channel index array for current stack 
        for icha = 1 : info.dims.nCoils(istk)
            chaidx = chaidxarr(icha) + 1;
            if(~isempty(receiver_nrs))
                recnr = receiver_nrs(icha);
            else
                recnr = -1;
            end
            fprintf('%20s(%d):%s at receiver %d\r', 'Cha', chaidx, info.dims.channel_names{chaidx}{1}, recnr);
        end
    end    
end


%  01 01 00: min_encoding_numbers         :         -224         -176            0            0
%  01 01 00: max_encoding_numbers         :          223          175            0            0
%  01 01 00: oversample_factors           :       2.0000       2.0000       1.0000       1.0000
%  01 01 00: spectrum_signs               :            1            1            1            1
%  01 01 00: spectrum_origins             :            0         -256            0            0
%- expression semantic: space(1)|    mix   |space(1)|  echo    |space(1)|two digits|colon|space(1)|min_encoding_numbers|space(n)|colon|space(n)number|space(n)|number|........ 
%- expample           :         |    01    |        |    02    |        |    00    |  :  |        |min_encoding_numbers|        |  :  |      -224         -176            0            0 
%- expression coding  :    \s   |   \d\d   |   \s   |   \d\d   |   \s   |   \d\d\  |  :  |   \s   |min_encoding_numbers|  \s*   |  :  |       (\s*\d+)+ 
expn = '\s(\d\d)\s(\d\d)\s\d\d\:\smin_encoding_numbers\s*:(\s*-?\d+)+[\r\n]';  % (\s*-?\d+)+ is a token expression - space followed by signed integer, at least once. [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
for itk = 1 : length(tokens)
    mix = str2num(tokens{itk}{1});
    ech = str2num(tokens{itk}{2});
    info.dims.min_encoding_numbers{mix, ech} = str2num(tokens{itk}{3});
end    
% consistency checking
assert(all(size(info.dims.min_encoding_numbers) == [info.dims.nMixes, max(info.dims.nEchoes)]), 'number of Mixes and Echoes must equal to size of min_encoding_numbers');
if p.Results.verbose == true
    for imix = 1 : size(info.dims.min_encoding_numbers,1)
    	for iech = 1 : size(info.dims.min_encoding_numbers,2)
            fprintf('%20s(%d,%d):[%s]\r', 'min_encoding_numbers', imix, iech, num2str(info.dims.min_encoding_numbers{imix,iech}));
        end
    end
end

expn = '\s(\d\d)\s(\d\d)\s\d\d\:\smax_encoding_numbers\s*:(\s*-?\d+)+[\r\n]';  % (\s*-?\d+)+ is a token expression - space followed by signed integer, at least once. [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
for itk = 1 : length(tokens)
    mix = str2num(tokens{itk}{1});
    ech = str2num(tokens{itk}{2});
    info.dims.max_encoding_numbers{mix, ech} = str2num(tokens{itk}{3});
end    
% consistency checking
assert(all(size(info.dims.max_encoding_numbers) == [info.dims.nMixes, max(info.dims.nEchoes)]), 'number of Mixes and Echoes must equal to size of max_encoding_numbers');
if p.Results.verbose == true
    for imix = 1 : size(info.dims.min_encoding_numbers,1)
    	for iech = 1 : size(info.dims.min_encoding_numbers,2)
            fprintf('%20s(%d,%d):[%s]\r', 'max_encoding_numbers', imix, iech, num2str(info.dims.max_encoding_numbers{imix,iech}));
        end
    end
end

expn = '\s(\d\d)\s(\d\d)\s\d\d\:\sspectrum_origins\s*:(\s*-?\d+)+[\r\n]';  % (\s*-?\d+)+ is a token expression - space followed by signed integer, at least once. [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
for itk = 1 : length(tokens)
    mix = str2num(tokens{itk}{1});
    ech = str2num(tokens{itk}{2});
    info.dims.spectrum_origins{mix, ech} = str2num(tokens{itk}{3});
end    
% consistency checking
assert(all(size(info.dims.spectrum_origins) == [info.dims.nMixes, max(info.dims.nEchoes)]), 'number of Mixes and Echoes must equal to size of max_encoding_numbers');
if p.Results.verbose == true
    for imix = 1 : size(info.dims.min_encoding_numbers,1)
    	for iech = 1 : size(info.dims.min_encoding_numbers,2)
            fprintf('%20s(%d,%d):[%s]\r', 'spectrum_origins', imix, iech, num2str(info.dims.spectrum_origins{imix,iech}));
        end
    end
end



%- initialize nKx, nKy, and nE3
info.dims.nKx = zeros(info.dims.nMixes, info.dims.nEchoes);

% obtain Kx, Ky, Kz, E3 from min_encoding_numbers and max_encoding_numbers
for imix = 1 : size(info.dims.min_encoding_numbers,1)
    for iech = 1 : size(info.dims.min_encoding_numbers,2)
        info.dims.nKx(imix, iech) =  info.dims.max_encoding_numbers{imix, iech}(1) - info.dims.min_encoding_numbers{imix, iech}(1)+1;
        info.dims.nKy(imix, iech) =  info.dims.max_encoding_numbers{imix, iech}(2) - info.dims.min_encoding_numbers{imix, iech}(2)+1;
        info.dims.nKz(imix, iech) =  info.dims.max_encoding_numbers{imix, iech}(3) - info.dims.min_encoding_numbers{imix, iech}(3)+1;
        info.dims.nE3(imix, iech) =  info.dims.max_encoding_numbers{imix, iech}(4) - info.dims.min_encoding_numbers{imix, iech}(4)+1;
    end
end


% recon_resolution, ignore mix index for now and assume there is on one mix
expn = '\s(\d\d)\s\d\d\s\d\d\:\srecon_resolutions\s*:(\s*\d+)+[\r\n]';  % (\s*-?\d+)+ is a token expression - space followed by signed integer, at least once. [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
for itok = 1 : length(tokens)
    mixno = str2num(tokens{itok}{1});
    info.dims.recon_resolutions(mixno, :) = str2num(tokens{1}{2});
end
 
if p.Results.verbose == true
    fprintf('%20s:[%s]\r', 'recon_resolution', num2str(info.dims.recon_resolutions(1,:)));
end

% oversampling factors
expn = '\s(\d\d)\s(\d\d)\s\d\d\:\soversample_factors\s*:(\s*[0-9]+.[0-9]+)+[\r\n]';  % (\s*[0-9]+.[0-9]+)+ is a token expression - space followed by positive floating number, at least once. [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
for itk = 1 : length(tokens)
    mix = str2num(tokens{itk}{1});
    ech = str2num(tokens{itk}{2});
    info.dims.oversample_factors{mix, ech} = str2num(tokens{itk}{3});
end    
% consistency checking
assert(all(size(info.dims.oversample_factors) == [info.dims.nMixes, max(info.dims.nEchoes)]), 'number of Mixes and Echoes must equal to size of oversample_factors');
if p.Results.verbose == true
    for imix = 1 : size(info.dims.oversample_factors,1)
    	for iech = 1 : size(info.dims.oversample_factors,2)
            fprintf('%20s(%d,%d):[%s]\r', 'oversample_factors', imix, iech, num2str(info.dims.oversample_factors{imix,iech}));
        end
    end
end

% 01 00 00: voxel_sizes                  :       0.7813       0.7813       0.6200
expn = '\s(\d\d)\s\d\d\s\d\d\:\svoxel_sizes\s*:(\s*[0-9]+.[0-9]+)+[\r\n]';  % (\s*[0-9]+.[0-9]+)+ is a token expression - space followed by positive floating number, at least once. [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
for itk = 1 : length(tokens)
    mix = str2num(tokens{itk}{1});
    info.dims.voxel_sizes{mix} = str2num(tokens{itk}{2});
end    
% consistency checking
assert( length(info.dims.voxel_sizes) == info.dims.nMixes, 'number of Mixes must equal to number of cells of voxel_sizes');
if p.Results.verbose == true
    for imix = 1 : size(info.dims.oversample_factors,1)
        fprintf('%20s(%d):[%s]\r', 'voxel_sizes', imix, num2str(info.dims.voxel_sizes{imix}));
    end
end

% sense factors
expn = '\s\d\d\s\d\d\s\d\d\:\ssense_factors\s*:(\s*[0-9]+.[0-9]+)+[\r\n]';  % (\s*[0-9]+.[0-9]+)+ is a token expression - space followed by positive floating number, at least once. [\r\n] either \r or \n - return or new line
tokens = regexp(str, expn, 'tokens');
if isempty(tokens)
    info.dims.sense_factors = [];
else
    info.dims.sense_factors  = str2num(tokens{1}{1});
    info.dims.sense_factors(4) = 1.0; % just to keep it the same lengh as recon_resoluitons etc.
end

% consistency checking
if p.Results.verbose == true
    fprintf('%20s:[%s]\r', 'sense_factors', num2str(info.dims.sense_factors));
end

% derive fourier length and freq_domain_length
if isempty(info.dims.sense_factors)                % no Sense 
    info.dims.fourier_lengths     = round(info.dims.recon_resolutions(1,1) .* info.dims.oversample_factors{1,1});
    info.dims.freq_domain_lengths = info.dims.recon_resolutions(1,1);
else
    for dim = 1 : 3
        if info.dims.sense_factors(dim) == 1       % sense but no unfolding
            info.dims.fourier_lengths(dim)     = round( info.dims.recon_resolutions(1,dim) * info.dims.oversample_factors{1,1}(dim) );
            info.dims.freq_domain_lengths(dim) = info.dims.recon_resolutions(1,dim);
        else                                       % sense with unfolding
            info.dims.fourier_lengths(dim)     = round( info.dims.recon_resolutions(1,dim) * info.dims.oversample_factors{1,1}(dim) / info.dims.sense_factors(dim)  );
            info.dims.freq_domain_lengths(dim) = round( info.dims.recon_resolutions(1,dim) * info.dims.oversample_factors{1,1}(dim) / info.dims.sense_factors(dim)  );
        end
    end            
end

% DC fixed data: ignore echo and location index for now.
%- expression semantic: space(1)|two digits(receiver nr)|space(1)|two digits(loc or eco)|space(1)|two digits(loc or eco)|colon|space(1)|dc_fixed_arr|space(n)|colon|space(n)number|space(n)|number|........ 
%-  01 00 00: dc_fixed_arr                 :  1.3904e-004  4.6348e-005  5.0983e-004 -4.6348e-005
%-  03 00 00: dc_fixed_arr                 :  4.6348e-005 -4.6348e-005 -9.2697e-005  4.6348e-005
%-  05 00 00: dc_fixed_arr                 :  0.0000e+000 -1.3904e-004 -3.7078e-004  1.1587e-003
%-  07 00 00: dc_fixed_arr                 :  4.6348e-004  5.0983e-004  2.3174e-004 -9.2697e-005
%- expression coding  :    \s   |   (\d\d)   |   \s   |   \d\d   |   \s   |   \d\d\          |  :  |   \s   |measured_channels|  \s*   |  :  |       (\s*\d+)+ 
expn = '\s(\d\d)\s\d\d\s\d\d\:\sdc_fixed_arr\s*:(\s*-?\d\.\d+e[+-]\d+)+[\r\n]';  % (\s*\d+)+ is a token expression - space followed by number, at least once. [\r\n] either \r or \n - return or new line 
tokens = regexp(str, expn, 'tokens');
% measured_channels_of_stacks = cell(1, info.dims.nStacks);
dc_fixed_arr = zeros(128, 1);
for itok = 1 : length(tokens)
   receiver_nr = str2num(tokens{1, itok}{1,1});                            % receiver_nr is the index (starting from 1)of ODU pins.
   %  assert(chano <= max(info.dims.nCoils), 'channel no read from dc_fixed_arr lines MUST be smaller or equal to number of coil channels!'); % this may not always be true so removed.
   dcoffset = str2num(tokens{1, itok}{1,2});
   dcoffset = dcoffset(1:2:end) + 1i*dcoffset(2:2:end);
   dc_fixed_arr(receiver_nr - 1 + (1 : length(dcoffset))) = dcoffset;
end
info.dc_fixed_arr = dc_fixed_arr;

if p.Results.verbose == true
    for icoil = 1 : length(info.dc_fixed_arr)
        fprintf('%20s %d has DC offset %0.4e + %0.4ei\r', 'Channel', icoil, real(info.dc_fixed_arr(icoil)), imag(info.dc_fixed_arr(icoil)) );
    end    
end

% total nr of external channels names
% 00 00 00: nr_channel_names             :            9
expn = '\s\d\d\s\d\d\s\d\d\:\snr_channel_names\s*:\s*(\d+)[\r\n]';  % (\d+)+ is a token expression - at least one digit number

tokens = regexp(str, expn, 'tokens');
assert(~isempty(tokens), 'parameter nr_channel_names MUST exist in sin file');
info.nr_channel_names = str2num(tokens{1}{1});
% pda
%- expression semantic: space(1)|two digits(ex cha nr)|space(1)|two digits|space(1)|two digits(gain setting)|colon|space(1)|pda_ampl_factors|space(n)|colon|space(n)number|space(n)|number|........ 
%  01 00 01: pda_ampl_factors             :       1.0000      -0.0000       1.6321       0.0016
%  03 00 01: pda_ampl_factors             :       2.5896      -0.0039       4.1605      -0.0111
%  05 00 01: pda_ampl_factors             :       5.6465      -0.0407       9.2009      -0.0707
%  07 00 01: pda_ampl_factors             :      14.5742      -0.1686      23.3963      -0.3099
%  09 00 01: pda_ampl_factors             :      35.9392      -0.6070      57.8866      -1.3749
%  11 00 01: pda_ampl_factors             :      90.0202      -3.8074     144.4092      -8.0769
%  01 00 02: pda_ampl_factors             :       1.0000      -0.0000       1.6315       0.0033
%  03 00 02: pda_ampl_factors             :       2.5889      -0.0011       4.1584      -0.0063
%  05 00 02: pda_ampl_factors             :       5.6309      -0.0432       9.1725      -0.0578
%  07 00 02: pda_ampl_factors             :      14.5331      -0.1514      23.3324      -0.2778
%  09 00 02: pda_ampl_factors             :      35.8275      -0.6015      57.6911      -1.3411
%  11 00 02: pda_ampl_factors             :      89.7154      -3.6751     143.6388      -8.2383
expn = '\s(\d\d)\s\d\d\s(\d\d)\:\spda_ampl_factors\s*:(\s*-?\d+\.\d+)+[\r\n]';  % (\s*\d+)+ is a token expression - space followed by number, at least once. [\r\n] either \r or \n - return or new line 
tokens = regexp(str, expn, 'tokens');
pda_ampl_factors = [];
rgsetnomax = 0; % number of gain settings.
for itok = 1 : length(tokens)
   rgsetno = str2num(tokens{1, itok}{1,1});
   exchano = str2num(tokens{1, itok}{1,2});
   assert(exchano <= info.nr_channel_names, 'channel no read from dc_fixed_arr lines MUST be smaller or equal to number of external channels!');
   if rgsetno > rgsetnomax
       rgsetnomax = rgsetno;
   end
   pda     = str2num(tokens{1, itok}{1,3});
   pda     = pda(1:2:end) + 1i*pda(2:2:end);
   pda_ampl_factors = horzcat(pda_ampl_factors, pda);                % may have more than one line, Concatenate lines.
end

if ~isempty(pda_ampl_factors)    
    norgset = length(pda_ampl_factors) / info.nr_channel_names;
    %assert( exchanr == info.nr_channel_names, 'number of external channels MUST equal!')
    pda_ampl_factors = reshape(pda_ampl_factors, [norgset, info.nr_channel_names]);    
    info.pda_ampl_factors = pda_ampl_factors;
else
    info.pda_ampl_factors = [];
end

%  00 00 13: loc_ap_rl_fh_row_image_oris  :       1.0000       0.0008       0.0000
%  00 00 13: loc_ap_rl_fh_col_image_oris  :       0.0000      -0.0024      -1.0000
expn = '\s\d\d\s\d\d\s(\d\d)\:\sloc_ap_rl_fh_row_image_oris\s*:(\s*-?\d+\.\d+)+[\r\n]';  % (\s*\d+)+ is a token expression - space followed by number, at least once. [\r\n] either \r or \n - return or new line 
tokens = regexp(str, expn, 'tokens');
for itk = 1 : length(tokens)
    lca = str2num(tokens{itk}{1});
    info.dims.loc_ap_rl_fh_row_image_oris{lca} = str2num(tokens{itk}{2});
end
assert( length(info.dims.loc_ap_rl_fh_row_image_oris) == info.dims.nLocations, 'number of locations must equal to number of cells of loc_ap_rl_fh_row_image_oris');

expn = '\s\d\d\s\d\d\s(\d\d)\:\sloc_ap_rl_fh_col_image_oris\s*:(\s*-?\d+\.\d+)+[\r\n]';  % (\s*\d+)+ is a token expression - space followed by number, at least once. [\r\n] either \r or \n - return or new line 
tokens = regexp(str, expn, 'tokens');
for itk = 1 : length(tokens)
    lca = str2num(tokens{itk}{1});
    info.dims.loc_ap_rl_fh_col_image_oris{lca} = str2num(tokens{itk}{2});
end
assert( length(info.dims.loc_ap_rl_fh_col_image_oris) == info.dims.nLocations, 'number of locations must equal to number of cells of loc_ap_rl_fh_col_image_oris');

expn = '\s\d\d\s\d\d\s(\d\d)\:\sloc_ap_rl_fh_offcentres\s*:(\s*-?\d+\.\d+)+[\r\n]';  % (\s*\d+)+ is a token expression - space followed by number, at least once. [\r\n] either \r or \n - return or new line 
tokens = regexp(str, expn, 'tokens');
for itk = 1 : length(tokens)
    lca = str2num(tokens{itk}{1});
    info.dims.loc_ap_rl_fh_offcentres{lca} = str2num(tokens{itk}{2});
end
assert( length(info.dims.loc_ap_rl_fh_offcentres) == info.dims.nLocations, 'number of locations must equal to number of cells of loc_ap_rl_fh_offcentres');

% 01 00 01: in_plane_transformations     :            5, // note: might be
% zero, but not likely.
expn = '\s(\d\d)\s\d\d\s(\d\d)\:\sin_plane_transformations\s*:\s*(\d+)[\r\n]'; 
% expn = '\s(\d\d)\s\d\d\s(\d\d)\:\snr_stacks\s*:\s*(\d+)[\r\n]';  % (\d+) is a token expression, [\r\n] either \r or \n - return or new line

tokens = regexp(str, expn, 'tokens');
for itk = 1 : length(tokens)
    mix = str2num(tokens{itk}{1});
    lca = str2num(tokens{itk}{2});
    info.dims.in_plane_transformations{mix, lca} = str2num(tokens{itk}{3});
end    
% consistency checking
assert(all(size(info.dims.in_plane_transformations) == [info.dims.nMixes, info.dims.nLocations]), 'number of Mixes and Locations must equal to size of in_plane_transformations');


%- expression semantic: space(1)|one digits|space(1)|one digits|space(1)|one digits|colon|space(1)|coca_cpx_file_names|space(n)|colon|space(1)|string for file name
%- expample           :         |     1    |        |    0     |        |    0     |  :  |        |coca_cpx_file_names|        |  :  |        |20171018_015542_SenseRefScan.cpx
%- expression coding  :    \s   |   (\d)   |   \s   |    \d    |   \s   |    \d    |  :  |   \s   |coca_cpx_file_names|  \s*   |  :  |  \s    |(\S+)[\r\n]
%  1 0 0: coca_cpx_file_names          : 20171018_015542_SenseRefScan.cpx
%  1 0 0: coca_rc_file_names           : 20171018_015542_SenseRefScan.rc 
%  2 0 0: coca_cpx_file_names          : 20171018_015542_SenseRefScan.cpx
%  2 0 0: coca_rc_file_names           : 20171018_015542_SenseRefScan.rc 
%  3 0 0: coca_cpx_file_names          : 20171018_015542_SenseRefScan.cpx
%  3 0 0: coca_rc_file_names           : 20171018_015542_SenseRefScan.rc 
expn = '\s(\d)\s\d\s\d\:\scoca_cpx_file_names\s*:\s(\S+)[\r\n]';  % (\S+)+ is a token expression - string of more than one non-white-space character. [\r\n] either \r or \n - return or new line 
tokens = regexp(str, expn, 'tokens');
coca_cpx_file_names = cell(1, info.dims.nStacks);
for itok = 1 : length(tokens)
   stackno = str2num(tokens{1, itok}{1,1});
   assert(stackno <= info.dims.nStacks, 'stack no read from measured_channels lines MUST be smaller or equal to number of stacks!');
   filstr = tokens{1, itok}{1,2};
   coca_cpx_file_names{stackno} = filstr;                % may have more than one line, Concatenate lines.
end
info.coca_cpx_file_names = coca_cpx_file_names;

% ------------------------- Coding History --------------------------------
% - 2017-01-20, C. Zhao, first version in Matlab R2012b. This file is added
%   to read SIN file, which contains all of the recon parameters.
% - 2017-07-27, C. Zhao, take care of mix, stak, echo dependency.


