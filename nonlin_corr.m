%%nonlin_corr     perform none linearity correction on Philips DDAS data
%
% outvec = nonlin_corr( info, idx, invec )
%
%   'info' the main info structure used through the program. 
%   preconditions:
%           info.NON_LIN_CORR must have been filled.
%   'idx' is the index of the label that belongs to the data vector to be
%   processed.
%
%   'invec' input vector
%   'outvec' output vector, none linearity corrected.
function  outvec = nonlin_corr( info, idx, invec )

% location nr
loc_nr = info.labels.Location.vals(idx);
% stack nr
stack_nr = info.sin.dims.loc_to_stack(loc_nr + 1);%

% Non linearity correction
normFactor = typecast(uint32(bitshift(info.labels.RconJobId.vals(idx), 16) + info.labels.Destination.vals(idx)), 'single');
factor     = normFactor / 10000.0;
info.loadopts.none_linearity_corr = 1;
if info.loadopts.none_linearity_corr && info.raw_format == 6  % verified: normFacor, factor, corrs, vector before and after correction are all correct.
    for internal_nr = 1 : size(invec, 2)
        externChannel = info.sin.dims.measured_channels_of_stacks{stack_nr+1}(internal_nr);
        nonLinLevels = zeros(1,length(info.NON_LIN_CORR.nonLinLevels{externChannel+1}) + 2);
        nonLinLevels(2:end-1) = info.NON_LIN_CORR.nonLinLevels{externChannel+1};
        nonLinLevels(1) = 0; nonLinLevels(end) = 1e10;
        
        nonLinCorrValues = zeros(1, length(nonLinLevels));
        nonLinCorrValues(2:end-1) = info.NON_LIN_CORR.nonLinCorrValues{externChannel+1};
        nonLinCorrValues(1) = nonLinCorrValues(2); nonLinCorrValues(end) = nonLinCorrValues(end-1);
        levels = abs(invec(:,internal_nr));
        levels = levels * normFactor;
        
        corrs = interp1(nonLinLevels, nonLinCorrValues, levels);
        
        invec(:, internal_nr) = invec(:, internal_nr) * factor;
        
        invec(:, internal_nr) = invec(:, internal_nr) .* corrs;
        
    end
else
    invec = invec * factor; 
end
    

outvec = invec;

% 
% ------------------------- Coding History --------------------------------
% - 2017-06-05. C. Zhao, , chenguang.z.zhao@philips.com
%   non linearity correction.
%