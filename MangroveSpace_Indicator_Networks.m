%% 载入SDG数据 load SDG data
clear; clc; close all
%Load data
% Load data from CSV file into a table
Table_Goals_All = readtable('global_goals01_21.csv');
Table_Indicators_All = readtable('global_indicators01_21.csv');
Table_Indicators_codebook = readtable('indicator_codebook.csv')

clc % Keep silent

% Get the table of regions
Table_Regions = table(Table_Indicators_All.country, ...
    Table_Indicators_All.Country, Table_Indicators_All.Region, ...
    'VariableNames', {'country', 'Country', 'Region'});
% Remove duplicate rows while keeping the original order
Table_Regions = unique(Table_Regions, 'rows', 'stable');

% Get the number of regions
n_Regions = height(Table_Regions);

IndicatorName = Table_Indicators_codebook.IndCode;
IndicatorName = string(IndicatorName);

% Get the table of indicators
Table_Indicators = table(IndicatorName, ...
    Table_Indicators_codebook.Indicator, Table_Indicators_codebook.Description, ...
    'VariableNames', {'Goal_Indicator', 'indicator_name', 'description'});



%%Get the 2001 data
Table_Goals_2001 = Table_Goals_All(Table_Goals_All.year==2001,:);
Table_Indicators_2001 = Table_Indicators_All(Table_Indicators_All.year==2001,:);
% Check if the country order is correct for the table we just got
is_equal_Table_Goals = strcmp(Table_Regions.country, Table_Goals_2001.country);
is_equal_Table_Indicators = strcmp(Table_Regions.country, Table_Indicators_2001.country);
if min([min(is_equal_Table_Goals), min(is_equal_Table_Indicators)]) ~= 1 % Wrong
    disp("Country order is wrong. Check!")
end
%%Get the 2011 data

Table_Goals_2011 = Table_Goals_All(Table_Goals_All.year==2011,:);
Table_Indicators_2011 = Table_Indicators_All(Table_Indicators_All.year==2011,:);
% Check if the country order is correct for the table we just got
is_equal_Table_Goals = strcmp(Table_Regions.country, Table_Goals_2011.country);
is_equal_Table_Indicators = strcmp(Table_Regions.country, Table_Indicators_2011.country);
if min([min(is_equal_Table_Goals), min(is_equal_Table_Indicators)]) ~= 1 % Wrong
    disp("Country order is wrong. Check!")
end
%% Load mangrove data

% Read the table from the "mangrove_indicators" sheet
Table_OriginalData = readtable('mangrove_indicators.xlsx', 'Sheet', 'mangrove_indicators');
Mangrove_names=readtable('mangrove_indicators.xlsx', 'Sheet','indicator_description')

% Fix wrong format
% Replace 'NA' with empty cells
Table_OriginalData.ECI_1996(strcmp(Table_OriginalData.ECI_1996, 'NA')) = {[]};
% Convert other strings to numbers
Table_OriginalData.ECI_1996 = cellfun(@str2double, Table_OriginalData.ECI_1996, 'UniformOutput', false);
% Convert it to a vector
Table_OriginalData.ECI_1996 = cell2mat(Table_OriginalData.ECI_1996);

% Save
save('Data_Main.mat', 'Table_Goals_All', 'Table_Indicators_All', ...
    'Table_Regions', 'n_Regions','Table_Indicators','Mangrove_names');


%%Change data 
Table_Data = Table_OriginalData;

% Specify the variable names to change the sign of
vars_to_negative = {'Sediment_Mean', 'n_eye_buf', 'n_eye_buf_1996_2006', 'n_eye_buf_2007_2016'};
% Loop through the variable names and change their sign
for i = 1:length(vars_to_negative)
    var_name = vars_to_negative{i};
    Table_Data.(var_name) = -Table_Data.(var_name);
end
clear i var_name

% Specify the names of the variables to remove (data discrapency)
vars_to_remove = {'CF_score', 'CF_score2'};
% Remove the specified variables from the table
Table_Data = removevars(Table_Data, vars_to_remove);

% Specify the names of the variables to cap at the 5th and 95th percentiles
vars_to_cap = {'area_1996_km2', 'area_2007_km2', 'area_2016_km2', ...
'Net_Change_1996_2007', 'Net_Change_2007_2016', 'Net_Change_1996_2016', ...
'Gross_Loss_1996_2007', 'Gross_Loss_2007_2016', 'Gross_Loss_1996_2016', ...
'Gross_Gain_1996_2007', 'Gross_Gain_2007_2016', 'Gross_Gain_1996_2016', ...
'Country_Area_1996_km2', 'Ramsar_ha', 'travel_mean', ...
'n_eye_buf', 'n_eye_buf_1996_2006', 'n_eye_buf_2007_2016'};
% Loop through the variable names and cap them at the 5th and 95th percentiles
for i = 1:length(vars_to_cap)
    var_name = vars_to_cap{i};
    percentiles = prctile(Table_Data.(var_name), [5, 95]);
    % Replace values outside the percentiles with the min/max of the variable
    Table_Data.(var_name)(Table_Data.(var_name) < percentiles(1)) = percentiles(1);
    Table_Data.(var_name)(Table_Data.(var_name) > percentiles(2)) = percentiles(2);
end
clear i var_name percentiles

% Normalize the variables to [0,1]
% Get the names of all variables except "ISO3C"
vars_to_normalize = Table_Data.Properties.VariableNames;
vars_to_normalize(strcmp(vars_to_normalize, 'ISO3C')) = [];
% Normalize
Table_Data(:,vars_to_normalize) = normalize(Table_Data(:,vars_to_normalize), 'range');
Table_Data{:,vars_to_normalize}=Table_Data{:,vars_to_normalize}*100

%% Calculate the networks of 96-07
% Variables to discard when constructing the network of 96-07
% 就是说，在构建96-07时间段的复杂网络时，这些变量不需要
vars_to_discard_96_07 = { 'area_2007_km2', 'area_2016_km2', ...
'Net_Change_2007_2016', 'Net_Change_1996_2016', ...
'Gross_Loss_2007_2016', 'Gross_Loss_1996_2016', ...
'Gross_Gain_2007_2016', 'Gross_Gain_1996_2016', ...
'VDEM_2007', 'VDEM_2016', 'BDH2020', ...
'ECI_2007', 'ECI_2016', ...
'lights_growth_07_13', 'lights_growth_07_13_sum', ...
'n_eye_buf', 'n_eye_buf_2007_2016', ...
'mean_SPEI_1979_2018', 'mean_SPEI_2007_2016'};
% Remove the specified variables from the table
Table_Data_96_07 = removevars(Table_Data, vars_to_discard_96_07);

% Get the variable names when constructing the network of 96-07
Variables_96_07 = Table_Data_96_07.Properties.VariableNames;
Variables_96_07 = Variables_96_07'; Variables_96_07 = string(Variables_96_07);

%% combine SDG and mangrove data
Mangrove_Goals_2001=innerjoin(Table_Data_96_07,Table_Goals_2001,'LeftKeys',1,'RightKeys',1);
Mangrove_Indicators_2001=innerjoin(Table_Data_96_07,Table_Indicators_2001,'LeftKeys',1,'RightKeys',1);

%%处理数据 data processing
vars_to_discard_Goal={'ISO3C','Country','year','Population','Region','IncomeGroup','SDGIndexScore'};
vars_to_discard_Indicator={'ISO3C','Country','year','Population','Region','IncomeGroup'};
Mangrove_Goals_96_07=removevars(Mangrove_Goals_2001, vars_to_discard_Goal);
Mangrove_Indicators_96_07=removevars(Mangrove_Indicators_2001, vars_to_discard_Indicator);

%% The complementarity network for mangrove protection
Net_Mangrove_Goal_Space_96_07 = NetworkSpace(table2array(Mangrove_Goals_96_07),'Product Space');
Net_Mangrove_Indicator_Space_96_07 = NetworkSpace(table2array(Mangrove_Indicators_96_07),'Product Space');
% The correlation network for mangrove protection
Net_MangroveCorr_Goals_96_07 = NetworkSpace(table2array(Mangrove_Goals_96_07),'Correlation');
% Save the above variables
writematrix(Net_Mangrove_Goal_Space_96_07, "Net_Mangrove_Goal_Space_96_07.csv");
writematrix(Net_Mangrove_Indicator_Space_96_07, "Net_Mangrove_Indicator_Space_96_07.csv");


save("SDG_Results_2001.mat",'Mangrove_Goals_96_07','Mangrove_Indicators_96_07')

%% Calculate the networks of 07-16
% Variables to discard when constructing the network of 96-07
% 就是说，在构建96-07时间段的复杂网络时，这些变量不需要
vars_to_discard_07_16 = { 'area_2007_km2', 'area_1996_km2', ...
'Net_Change_1996_2007', 'Net_Change_1996_2016', ...
'Gross_Loss_1996_2007', 'Gross_Loss_1996_2016', ...
'Gross_Gain_1996_2007', 'Gross_Gain_1996_2016', ...
'VDEM_2007', 'VDEM_1996', ...
'ECI_2007', 'ECI_1996', 'BDH2010',...
'lights_growth_96_07', 'lights_growth_96_07_sum', ...
'n_eye_buf', 'n_eye_buf_1996_2006', ...
'mean_SPEI_1979_2018', 'mean_SPEI_1996_2006'};
% Remove the specified variables from the table
Table_Data_07_16 = removevars(Table_Data, vars_to_discard_07_16);

% Get the variable names when constructing the network of 96-07
Variables_07_16 = Table_Data_07_16.Properties.VariableNames;
Variables_07_16 = Variables_07_16'; Variables_07_16 = string(Variables_07_16);

%% combine SDG and mangrove data
Mangrove_Goals_2011=innerjoin(Table_Data_07_16,Table_Goals_2011,'LeftKeys',1,'RightKeys',1);
Mangrove_Indicators_2011=innerjoin(Table_Data_07_16,Table_Indicators_2011,'LeftKeys',1,'RightKeys',1);

%%处理数据
vars_to_discard_Goal={'ISO3C','Country','year','Population','Region','IncomeGroup','SDGIndexScore'};
vars_to_discard_Indicator={'ISO3C','Country','year','Population','Region','IncomeGroup'};
Mangrove_Goals_07_16=removevars(Mangrove_Goals_2011, vars_to_discard_Goal);
Mangrove_Indicators_07_16=removevars(Mangrove_Indicators_2011, vars_to_discard_Indicator);

%% The complementarity network for mangrove protection 07-16
Net_Mangrove_Goal_Space_07_16 = NetworkSpace(table2array(Mangrove_Goals_07_16),'Product Space');
Net_Mangrove_Indicator_Space_07_16 = NetworkSpace(table2array(Mangrove_Indicators_07_16),'Product Space');
Net_MangroveCorr_Goal_07_16 = NetworkSpace(table2array(Mangrove_Goals_07_16),'Correlation');
%% The correlation network for mangrove protection

Net_MangroveCorr_Indi_07_16 = NetworkSpace(table2array(Mangrove_Indicators_07_16),'Correlation');
Net_MangroveCorr_Indi_96_07 = NetworkSpace(table2array(Mangrove_Indicators_96_07),'Correlation');

Net_MangroveCorr_Indicator_07_16 = Net_MangroveCorr_Indi_07_16(all(~isnan(Net_MangroveCorr_Indi_07_16),2),:); % for nan - rows
Net_MangroveCorr_Indicator_07_16 = Net_MangroveCorr_Indi_07_16(:,all(~isnan(Net_MangroveCorr_Indi_07_16)));   % for nan - columns

Net_MangroveCorr_Indicators_96_07 = Net_MangroveCorr_Indi_96_07(all(~isnan(Net_MangroveCorr_Indi_96_07),2),:); % for nan - rows
Net_MangroveCorr_Indicators_96_07 = Net_MangroveCorr_Indi_96_07(:,all(~isnan(Net_MangroveCorr_Indi_96_07)));   % for nan - columns

%% 计算 (stability)

rca_goal_per = (norm(Net_Mangrove_Goal_Space_96_07-Net_Mangrove_Goal_Space_07_16))./(norm(Net_Mangrove_Goal_Space_07_16))
rca_indicator_per= (norm(Net_Mangrove_Indicator_Space_96_07-Net_Mangrove_Indicator_Space_07_16))./(norm(Net_Mangrove_Indicator_Space_07_16))
corr_goal_per= (norm(Net_MangroveCorr_Goals_96_07-Net_MangroveCorr_Goal_07_16))./(norm(Net_MangroveCorr_Goal_07_16))
corr_indicator_per= (norm(Net_MangroveCorr_Indicators_96_07-Net_MangroveCorr_Indicator_07_16))./(norm(Net_MangroveCorr_Indicator_07_16))

%% The complementarity network for mangrove protection
Net_Mangrove_Goal_Space_07_16 = NetworkSpace(table2array(Mangrove_Goals_07_16),'Product Space');
Net_Mangrove_Indicator_Space_07_16 = NetworkSpace(table2array(Mangrove_Indicators_07_16),'Product Space');
% The correlation network for mangrove protection
Net_MangroveCorr_07_16 = NetworkSpace(table2array(Mangrove_Goals_07_16),'Correlation');

% Save the above variables
writematrix(Net_Mangrove_Goal_Space_07_16, "Net_Mangrove_Goal_Space_07_16.csv");
writematrix(Net_Mangrove_Indicator_Space_07_16, "Net_Mangrove_Indicator_Space_07_16.csv");
writematrix(Net_MangroveCorr_07_16, "Net_MangroveCorr_07_16.csv");

save("SDG_Results_2011.mat",'Mangrove_Goals_07_16','Mangrove_Indicators_07_16')
