function NetMatrix = NetworkSpace(IndicatorMatrix, Type)
%{
Output: NetMatrix is the matrix representation of the network 
        for the interactions between the indicators.
Input: (1) IndicatorMatrix is a matrix, where
           each column represents an indictor, and
           each row represents an agent (such a region or an individual).
       (2) Type is the type of the network:
           (a) If it is 'Product Space', then the network corresponds to 
               COMPLEMENTARITIES between the indicators, as in the paper
               Hidalgo, César A., et al. 
               "The product space conditions the development of nations." 
               Science 317.5837 (2007): 482-487.
           (b) If it is 'Correlation', then the network corresponds to
               CORRELATIONS between the indicators, as in the paper
               Wu, Xutong, et al. 
               "Decoupling of SDGs followed by re-coupling as sustainable development progresses."
               Nature Sustainability 5.5 (2022): 452-459.
Note: The input CAN contain some missing variables!
%}

% Column number, i.e., indicator number
num_cols = size(IndicatorMatrix, 2);
% Construct the matrix for the network
switch Type
    case 'Product Space'
        % Fill the missing values with column means
        Mean_Indicators = mean(IndicatorMatrix,'omitnan');
        IndicatorMatrix = fillmissing(IndicatorMatrix,'constant',Mean_Indicators);
        % Calculate variables
        shares_1 = diag( ( 1 ./ sum(IndicatorMatrix,2) ) ) * IndicatorMatrix;
        shares_2 = sum(IndicatorMatrix) / sum(IndicatorMatrix,'all');
        RCA = shares_1 / diag(shares_2);
        RCA = RCA>1; % Revealed Comparative Advantage
        % Construct network matrix
        Net_RCA = RCA' * RCA ./ ...
            max(repmat(sum(RCA),num_cols,1),repmat(sum(RCA)',1,num_cols));
        Net_RCA = Net_RCA - diag(diag(Net_RCA)); % Set diagonal elements to 0
        % Return
        NetMatrix = Net_RCA;
    case 'Correlation'
        % Construct network matrix
        Net_Corr = corrcoef(IndicatorMatrix,"Rows","pairwise");
        Net_Corr = Net_Corr - diag(diag(Net_Corr)); % Set diagonal elements to 0
        % Check whether missing values exist in the network
        if sum(isnan(Net_Corr),"all")>0
            disp("Missing values exist in the correlation network. " ...
                + "This may be due to too many missing values in the relavent variables. " ...
                + "Please check!")
        end
        % Return
        NetMatrix = Net_Corr;
    otherwise
        disp('The type of your network space is not supported!')
        % Return
        NetMatrix = 'Undefined';
end

end