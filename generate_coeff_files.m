%% Параметры

DATA_PATH               = 'C:\MyFolder\RemoteFolder\projects\';
DATA_WIDTH              = 14;
INPUT_DATA_FILE_NAME    = 'data_in.txt';
OUTPUT_DATA_FILE_NAME   = 'data_out.txt';

N   = 128;
FS  = 20*10^6;
AMP = 10;

DIFF_COEFF_FILE_NAME    = 'diff_coeff';
DIFF_COEFF_WL_FILE_NAME = 'diff_coeff_wl';
DIFF_COEFF_FL_FILE_NAME = 'diff_coeff_fl';

INTEGR_COEFF_FILE_NAME    = 'integr_coeff';
INTEGR_COEFF_WL_FILE_NAME = 'integr_coeff_wl';
INTEGR_COEFF_FL_FILE_NAME = 'integr_coeff_fl';

DATA_TYPE = 'int16';
%% Перевод коэффициентов КИХ-фильтра (дифференциатора) в int
% Для дальнейшего использования в RTL будем собирать коэффициенты в 64-битные слова
% а уже в самом RTL считываемые слова разделим согласно ширине
% коэффициентов на отдельыне части

% Короче, по итогу проще записать текстовый файл. Просто там размещу в
% текстовом формате. И тогда получается, что вся обработка упрощается

diff_coeff = [-0.016686934099368,
              0.195507800433580,
              -0.394962749734687,
              0.433866959174206,
              0.597244731023441];

wordlength_diff        = [8, 9, 9, 6, 7];
fractional_length_diff = [6, 7, 7, 4, 5];

coeff_diff_int = zeros(1, length(diff_coeff));
cumm_coeff_num = ceil((sum(wordlength_diff) + length(wordlength_diff))/64);
cumm_coeff     = zeros(1, cumm_coeff_num);

cumm_coeff_idx = 1;

a = '';
for i = 1:length(coeff_diff_int)
    fp_tmp            = fi(diff_coeff(i), 1, wordlength_diff(i), ...
                           fractional_length_diff(i));
    dec2hex(fp_tmp.int);
    a = [fp_tmp.bin ,a];
    if (diff_coeff(i) < 0)
        fp_fill_zero     = fi(0, 0, wordlength_diff(i)+1); %нельзя произвести битовый сдвиг, если число отрицательное 
        fp_fill_zero.bin = ['0', fp_tmp.bin];
        fp_tmp           = fp_fill_zero;
    end

    coeff_diff_int(i) = fp_tmp.int;
    if (i == 1)
        cumm_coeff(cumm_coeff_idx) = coeff_diff_int(1);
        shift      = wordlength_diff(i) + 1;
    else
        cumm_coeff(cumm_coeff_idx) = cumm_coeff(cumm_coeff_idx) + bitshift(coeff_diff_int(i), shift);
        shift = shift + wordlength_diff(i) + 1;
        if (shift >= 64)
            shift = 0;
            cumm_coeff_idx = cumm_coeff_idx + 1;
        end
    end
end
b = bin2dec(a);
b = dec2hex(b);
%% Запись данных о коэффициентах КИХ-фильтра (дифференциатора)

diff_coeff_file_path = [DATA_PATH, DIFF_COEFF_FILE_NAME, '.bin'];
file_id = fopen(diff_coeff_file_path, 'wb');
fwrite(file_id, coeff_diff_int, DATA_TYPE, 'native');
fclose(file_id);

diff_coeff_wd_file_path = [DATA_PATH, DIFF_COEFF_WL_FILE_NAME, '.bin'];
file_id = fopen(diff_coeff_wd_file_path, 'wb');
fwrite(file_id, wordlength_diff, DATA_TYPE, 'ieee-be');
fclose(file_id);

diff_coeff_fl_file_path = [DATA_PATH, DIFF_COEFF_FL_FILE_NAME, '.bin'];
file_id = fopen(diff_coeff_fl_file_path, 'wb');
fwrite(file_id, fractional_length_diff, DATA_TYPE, 'ieee-be');
fclose(file_id);

%% Перевод коэффициентов КИХ-фильтра (дифференциатора) в int
tick_coeff = [0.3584,
              1.2832,
              0.3584
              ];

wordlength_integr        = [7, 6, 7];
fractional_length_integr = [6, 5, 6];

coeff_integr_int = zeros(1, length(tick_coeff));

cumm_coeff_num = ceil((sum(wordlength_integr))/64);
cumm_coeff     = zeros(1, cumm_coeff_num);

cumm_coeff_idx = 1;
for i = 1:length(tick_coeff)
    fp_tmp            = fi(tick_coeff(i), 0, wordlength_integr(i), ...
                           fractional_length_integr(i));

    dec2hex(fp_tmp.int)
    coeff_integr_int(i) = fp_tmp.int;
    if (i == 1)
        cumm_coeff(cumm_coeff_idx) = coeff_integr_int(1);
        shift      = wordlength_integr(i) + 1;
    else
        cumm_coeff(cumm_coeff_idx) = cumm_coeff(cumm_coeff_idx) + bitshift(coeff_integr_int(i), shift);
        shift = shift + wordlength_integr(i) + 1;
        if (shift >= 64)
            shift = 0;
            cumm_coeff_idx = cumm_coeff_idx + 1;
        end
    end
end

%% Запись данных о коэффициентах КИХ части интегратора

integr_coeff_file_path = [DATA_PATH, INTEGR_COEFF_FILE_NAME, '.bin'];
file_id = fopen(integr_coeff_file_path, 'wb');
fwrite(file_id, coeff_integr_int, DATA_TYPE, 'ieee-be');
fclose(file_id);

integr_coeff_wl_file_path = [DATA_PATH, INTEGR_COEFF_WL_FILE_NAME, '.bin'];
file_id = fopen(integr_coeff_wl_file_path, 'wb');
fwrite(file_id, wordlength_integr, DATA_TYPE, 'ieee-be');
fclose(file_id);

integr_coeff_fl_file_path = [DATA_PATH, INTEGR_COEFF_FL_FILE_NAME, '.bin'];
file_id = fopen(integr_coeff_fl_file_path, 'wb');
fwrite(file_id, fractional_length_integr, DATA_TYPE, 'ieee-be');
fclose(file_id);

%% Генерирование входных данных
f = FS/8;
t = 0:1/FS:(N-1)/FS;
signal = int16(AMP * sin(2*pi*f*t));
file_id = fopen([DATA_PATH, INPUT_DATA_FILE_NAME], 'w');
for i = 1:N
    bin_repr = dec2bin(signal(i));
    if length(bin_repr) < DATA_WIDTH
        zero_num = DATA_WIDTH - length(bin_repr); 
        for j = 1:zero_num
            if (signal(i) < 0)
                bin_repr = ['1', bin_repr];
            else
                bin_repr = ['0', bin_repr];
            end
        end
    end
    
    fprintf(file_id, '%s\n', bin_repr);
end
fclose(file_id);