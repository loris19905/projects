%%
estimate_resolution;
Start;
clear all;
clc;
close all;
%% Параметры

FILTER_MODE    = 'integrator'; % 'integrator', 'differentiator'
GET_INPUT_DATA = 'read';       % 'generate', 'read'

%% Начальные данные
INT16_SIZE              = 16;
DATA_WIDTH              = 14;

DATA_PATH               = '..\data\';
INPUT_DATA_FILE_NAME    = 'data_in.txt';
OUTPUT_DATA_FILE_NAME   = 'data_out.txt';
MODEL_DATA_FILE_NAME    = ['model_data', '_', FILTER_MODE];

N   = 128;
FS  = 20*10^6;
AMP = 10;

WORDLENGTH        = 14;
FRACTIONAL_LENGTH = 6;

DIFF_COEFF_FILE_NAME   = 'diff_coeff';
INTEGR_COEFF_FILE_NAME = 'integr_coeff';

DATA_TYPE = 'int16';

%% Запись коэффцицента КИХ-фильтра (дифференциатора)

% Есть идея собрать в текстовом виде все коэффициенты фильтра в 1 строку
% В самом rtl, зная длину слова каждого коэффициента, можно будет путем
% не хитрой адресации написать нормальный код.

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

cumm_coeff_idx = '';

% a = '';
% for i = 1:length(coeff_diff_int)
%     fp_tmp            = fi(diff_coeff(i), 1, wordlength_diff(i), ...
%                            fractional_length_diff(i));
%     dec2hex(fp_tmp.int);
%     a = [fp_tmp.bin ,a];
%     if (diff_coeff(i) < 0)
%         fp_fill_zero     = fi(0, 0, wordlength_diff(i)+1); %нельзя произвести битовый сдвиг, если число отрицательное 
%         fp_fill_zero.bin = ['0', fp_tmp.bin];
%         fp_tmp           = fp_fill_zero;
%     end
% 
%     coeff_diff_int(i) = fp_tmp.int;
%     if (i == 1)
%         cumm_coeff(cumm_coeff_idx) = coeff_diff_int(1);
%         shift      = wordlength_diff(i) + 1;
%     else
%         cumm_coeff(cumm_coeff_idx) = cumm_coeff(cumm_coeff_idx) + bitshift(coeff_diff_int(i), shift);
%         shift = shift + wordlength_diff(i) + 1;
%         if (shift >= 64)
%             shift = 0;
%             cumm_coeff_idx = cumm_coeff_idx + 1;
%         end
%     end
% end
% b = bin2dec(a);
% b = dec2hex(b);
%% Запись данных о коэффициентах КИХ-фильтра (дифференциатора)

% diff_coeff_file_path = [DATA_PATH, DIFF_COEFF_FILE_NAME, '.bin'];
% file_id = fopen(diff_coeff_file_path, 'wb');
% fwrite(file_id, coeff_diff_int, DATA_TYPE, 'native');
% fclose(file_id);
% 
% diff_coeff_wd_file_path = [DATA_PATH, DIFF_COEFF_WL_FILE_NAME, '.bin'];
% file_id = fopen(diff_coeff_wd_file_path, 'wb');
% fwrite(file_id, wordlength_diff, DATA_TYPE, 'ieee-be');
% fclose(file_id);
% 
% diff_coeff_fl_file_path = [DATA_PATH, DIFF_COEFF_FL_FILE_NAME, '.bin'];
% file_id = fopen(diff_coeff_fl_file_path, 'wb');
% fwrite(file_id, fractional_length_diff, DATA_TYPE, 'ieee-be');
% fclose(file_id);

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
% for i = 1:length(tick_coeff)
%     fp_tmp            = fi(tick_coeff(i), 0, wordlength_integr(i), ...
%                            fractional_length_integr(i));
% 
%     dec2hex(fp_tmp.int)
%     coeff_integr_int(i) = fp_tmp.int;
%     if (i == 1)
%         cumm_coeff(cumm_coeff_idx) = coeff_integr_int(1);
%         shift      = wordlength_integr(i) + 1;
%     else
%         cumm_coeff(cumm_coeff_idx) = cumm_coeff(cumm_coeff_idx) + bitshift(coeff_integr_int(i), shift);
%         shift = shift + wordlength_integr(i) + 1;
%         if (shift >= 64)
%             shift = 0;
%             cumm_coeff_idx = cumm_coeff_idx + 1;
%         end
%     end
% end

%% Запись данных о коэффициентах КИХ части интегратора

% integr_coeff_file_path = [DATA_PATH, INTEGR_COEFF_FILE_NAME, '.bin'];
% file_id = fopen(integr_coeff_file_path, 'wb');
% fwrite(file_id, coeff_integr_int, DATA_TYPE, 'ieee-be');
% fclose(file_id);
% 
% integr_coeff_wl_file_path = [DATA_PATH, INTEGR_COEFF_WL_FILE_NAME, '.bin'];
% file_id = fopen(integr_coeff_wl_file_path, 'wb');
% fwrite(file_id, wordlength_integr, DATA_TYPE, 'ieee-be');
% fclose(file_id);
% 
% integr_coeff_fl_file_path = [DATA_PATH, INTEGR_COEFF_FL_FILE_NAME, '.bin'];
% file_id = fopen(integr_coeff_fl_file_path, 'wb');
% fwrite(file_id, fractional_length_integr, DATA_TYPE, 'ieee-be');
% fclose(file_id);

%% Генерирование входных данных
if strcmp(GET_INPUT_DATA, 'generate')
    f = FS/8;
    t = 0:1/FS:(N-1)/FS;
    signal = round(AMP * sin(2*pi*f*t) * (2^FRACTIONAL_LENGTH));
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
        elseif length(bin_repr) > DATA_WIDTH
            delete_bits_num = length(bin_repr) - WORDLENGTH; % во время представления
                                          % отрицательных чисел в двоичном
                                          % формате в виде текста Matlab
                                          % добавляет некоторое количество
                                          % единиц в конце строки
            bin_repr(1:delete_bits_num) = [];
        end
        
        fprintf(file_id, '%s\n', bin_repr);
    end
    fclose(file_id);
elseif strcmp(GET_INPUT_DATA, 'read')

    file_id     = fopen([DATA_PATH, INPUT_DATA_FILE_NAME]);
    signal_char = fscanf(file_id, '%s\n');
    fclose(file_id);

    file_id    = fopen([DATA_PATH, MODEL_DATA_FILE_NAME]);
    model_dec  = fread(file_id, N, 'double');
    fclose(file_id);
 
    signal_dec = zeros(1, N);
    for i = 1:N
        a = fi(0,1,WORDLENGTH, FRACTIONAL_LENGTH);
        a.bin = signal_char((i-1)*WORDLENGTH+1:i*WORDLENGTH);
        signal_dec(i) = double(a);
    end

else
    error("Неправильно выбран способ получения входного сигнала")
end

%% Ожидание запуска симуляции
disp("Запустите симуляцию")
pause();

%% Обработка данных симуляции

file_id       = fopen([DATA_PATH, OUTPUT_DATA_FILE_NAME], 'r');
filter_output = fscanf(file_id, '%s');
fclose(file_id);
hex_symb_in_int16 = 4;
filter_output_dec = zeros(1, length(filter_output)/hex_symb_in_int16);
for i = 1:round(length(filter_output)/hex_symb_in_int16)
    a = fi(0,1,WORDLENGTH, FRACTIONAL_LENGTH);
    a.hex = filter_output((i-1)*hex_symb_in_int16+1:i*hex_symb_in_int16);
    filter_output_dec(i) = double(a);
end
plot(filter_output_dec)
hold on 
plot(model_dec)
