%% Параметры

DATA_PATH               = 'C:\MyFolder\RemoteFolder\projects\';

DIFF_COEFF_FILE_NAME    = 'diff_coeff';
DIFF_COEFF_WD_FILE_NAME = 'diff_coeff_wd';
DIFF_COEFF_FL_FILE_NAME = 'diff_coeff_fl';

INTEGR_COEFF_FILE_NAME    = 'integr_coeff';
INTEGR_COEFF_WD_FILE_NAME = 'integr_coeff_wd';
INTEGR_COEFF_FL_FILE_NAME = 'integr_coeff_fl';

DATA_TYPE = 'int16';
%% Перевод коэффициентов КИХ-фильтра (дифференциатора) в int
diff_coeff = [-0.016686934099368,
              0.195507800433580,
              -0.394962749734687,
              0.433866959174206,
              0.597244731023441];

wordlength_diff        = [8, 9, 9, 6, 7];
fractional_length_diff = [6, 7, 7, 4, 5];

coeff_diff_int = zeros(1, length(diff_coeff));
for i = 1:length(coeff_diff_int)
    fp_tmp            = fi(diff_coeff(i), 1, wordlength_diff(i), ...
                           fractional_length_diff(i));
    coeff_diff_int(i) = fp_tmp.int;
end

%% Запись данных о коэффициентах КИХ-фильтра (дифференциатора)

diff_coeff_file_path = [DATA_PATH, DIFF_COEFF_FILE_NAME, '.txt'];
file_id = fopen(diff_coeff_file_path, 'wb');
fwrite(file_id, coeff_diff_int, DATA_TYPE);
fclose(file_id);

diff_coeff_wd_file_path = [DATA_PATH, DIFF_COEFF_WD_FILE_NAME, '.txt'];
file_id = fopen(diff_coeff_wd_file_path, 'wb');
fwrite(file_id, wordlength_diff, DATA_TYPE);
fclose(file_id);

diff_coeff_fl_file_path = [DATA_PATH, DIFF_COEFF_FL_FILE_NAME, '.txt'];
file_id = fopen(diff_coeff_fl_file_path, 'wb');
fwrite(file_id, fractional_length_diff, DATA_TYPE);
fclose(file_id);

%% Перевод коэффициентов КИХ-фильтра (дифференциатора) в int
tick_coeff = [0.3584,
              1.2832,
              0.3584
              ];

wordlength_integr        = [1, 1, 1];
fractional_length_integr = [6, 5, 6];

coeff_integr_int = zeros(1, length(tick_coeff));
for i = 1:length(tick_coeff)
    fp_tmp            = fi(tick_coeff(i), 0, wordlength_integr(i), ...
                           fractional_length_integr(i));
    coeff_integt_int(i) = fp_tmp.int;
end

%% Запись данных о коэффициентах КИХ части интегратора

integr_coeff_file_path = [DATA_PATH, INTEGR_COEFF_FILE_NAME, '.txt'];
file_id = fopen(integr_coeff_file_path, 'wb');
fwrite(file_id, coeff_integr_int, DATA_TYPE);
fclose(file_id);

integr_coeff_wd_file_path = [DATA_PATH, INTEGR_COEFF_WD_FILE_NAME, '.txt'];
file_id = fopen(integr_coeff_wd_file_path, 'wb');
fwrite(file_id, wordlength_integr, DATA_TYPE);
fclose(file_id);

integr_coeff_fl_file_path = [DATA_PATH, INTEGR_COEFF_FL_FILE_NAME, '.txt'];
file_id = fopen(integr_coeff_fl_file_path, 'wb');
fwrite(file_id, fractional_length_integr, DATA_TYPE);
fclose(file_id);