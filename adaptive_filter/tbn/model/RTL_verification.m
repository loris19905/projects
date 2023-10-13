%%
estimate_resolution;
clearvars -except coeff_integrator coeff;
clc;
close all;
%% Параметры

FILTER_MODE    = 'differentiator'; % 'integrator', 'differentiator'
GET_INPUT_DATA = 'generate';       % 'generate', 'read'
START_RTL      = 1;
DEBUG          = 1;

N    = 128;
FS   = 1;
AMP  = 10;

%% Начальные данные
INT16_SIZE              = 16;
DATA_WIDTH              = 14;

DATA_PATH             = '..\data\';
INPUT_DATA_FILE_NAME  = 'data_in.txt';
OUTPUT_DATA_FILE_NAME = 'data_out.txt';
MODEL_DATA_FILE_NAME  = ['model_data', '_', FILTER_MODE, '.txt'];

FILTER_ORDER = 9;
MULT_NUM     = (FILTER_ORDER + 1) / 2;
DIFF_NUM     = MULT_NUM;
Time = N/FS;


WORDLENGTH        = 14;
FRACTIONAL_LENGTH = 6;

OP_DIFF_WL = 15;
OP_DIFF_FL = 6;

WORDLENGTH_MULT = [18, 19, 20, 14, 14];
FRACLENGTH_MULT = [12, 11, 12, 6, 6];

DATA_TYPE = 'int16';

%% Генерирование входных данных

if strcmp(GET_INPUT_DATA, 'generate')
    f = FS/8;
    t = 0:1/FS:(N-1)/FS;
    signal  = AMP * sin(2*pi*f*t);
    file_id = fopen([DATA_PATH, INPUT_DATA_FILE_NAME], 'w');
    signal_fix = round(signal * 2^FRACTIONAL_LENGTH);
    for i = 1:N
        bin_repr = dec2bin(signal_fix(i));
        if length(bin_repr) < DATA_WIDTH
            zero_num = DATA_WIDTH - length(bin_repr); 
            for j = 1:zero_num
                if (signal_fix(i) < 0)
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

    file_id     = fopen([DATA_PATH, INPUT_DATA_FILE_NAME], 'r');
    signal_char = fscanf(file_id, '%s\n');
    fclose(file_id);

    file_id    = fopen([DATA_PATH, MODEL_DATA_FILE_NAME], 'rb');
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

if (isequal(FILTER_MODE, 'differentiator'))
    ctrl = zeros(1, length(t));
elseif isequal(FILTER_MODE, 'integrator') 
    ctrl = ones(1, length(t));
end
ctrl = [t', ctrl'];
test_signal = [t', signal'];

%% Запуск модели в Simulink
ts = 1/FS;
model_dec = start_simulink(signal, t, DEBUG, DATA_PATH);
file_id = fopen([DATA_PATH, MODEL_DATA_FILE_NAME], 'w');
for i = 1:N
    model_str = dec2bin(round(model_dec(i) * 2^FRACTIONAL_LENGTH));
    if (length(model_str) < WORDLENGTH)
        if (model_dec(i) >= 0)
            for j = 1 : WORDLENGTH - length(model_str)
                model_str = ['0', model_str];
            end
        elseif (model_dec(i) < 0)
            for j = 1 : WORDLENGTH - length(model_str)
                model_str = ['1', model_str];
            end
        end
    elseif (length(model_str) > WORDLENGTH)
        model_str(1:length(model_str)-WORDLENGTH) = [];
    end
    fprintf(file_id, '%s\n', model_str);
end
fclose(file_id);


%% Ожидание запуска симуляции
if (START_RTL)
    disp("Запустите симуляцию")
    pause();
end

%% Обработка данных симуляции
if (DEBUG)
    filter_output = read_data_from_sim([DATA_PATH, OUTPUT_DATA_FILE_NAME], N, ...
                                       WORDLENGTH, FRACTIONAL_LENGTH);
    
    mult_rtl   = zeros(N, MULT_NUM);
    mult_model = zeros(N, MULT_NUM);
    
    diff_rtl   = zeros(1, MULT_NUM*N);
    diff_model = zeros(N, MULT_NUM);
    
    for i = 1:(FILTER_ORDER+1)/2
        mult_rtl(:, i) = read_data_from_sim([DATA_PATH, 'mult_', num2str(i-1), '.txt'], ...
                                            N, WORDLENGTH_MULT(i), FRACLENGTH_MULT(i));
        
        file_id         = fopen([DATA_PATH, 'mult_', num2str(i-1)], 'rb');
        mult_model(:,i) = fread(file_id, N, 'double');
        fclose(file_id);
    
        file_id         = fopen([DATA_PATH, 'diff_', num2str(i-1)], 'rb');
        diff_model(:,i) = fread(file_id, N, 'double');
        fclose(file_id);
    
    end
    
    diff_rtl = read_data_from_sim([DATA_PATH, 'diff', '.txt'], ...
                                  N*MULT_NUM, OP_DIFF_WL, OP_DIFF_FL);
    
    diff_rtl = reshape(diff_rtl, DIFF_NUM, N);
    diff_rtl = diff_rtl';
    
    plot(filter_output)
    hold on 
    plot(model_dec)
    hold off
    
    if (isequal(diff_model, diff_rtl))
        disp("Данные с выхода блоков вычитания совпали")
    else
        disp("ОШИБКА!! Данные с выхода блоков вычитания не совпали")
    end
    
    if (isequal(mult_model, mult_rtl))
        disp("Данные с выхода умножителей совпали")
    else
        disp("ОШИБКА!! Данные с выхода умножителей не совпали")
    end
    
    if (isequal(filter_output, model_dec(1:N)'))
        disp("Simulink-модель совпала с RTL")
    else
        disp("ОШИБКА!! RTL не соответствует Simulink-модели")
    end

end

%% Функции

function output_data = start_simulink(signal, t, debug, file_path)
    
    
    if nargin < 3
        debug = 0;
    end

    if ((nargin < 4) && debug)
        file_path = '.\';
    end

    test_signal = [t', signal'];

    sim("models_diff_integr.slx");
    output_data = ans.fp_out_signal.data;

    mult_0_data = ans.mult_0.data;
    mult_1_data = ans.mult_1.data;
    mult_2_data = ans.mult_2.data;
    mult_3_data = ans.mult_3.data;
    mult_4_data = ans.mult_4.data;

    diff_0_data = ans.diff_0.data;
    diff_1_data = ans.diff_1.data;
    diff_2_data = ans.diff_2.data;
    diff_3_data = ans.diff_3.data;
    diff_4_data = ans.diff_4.data;
    
    if (debug)

        file_id = fopen([file_path, 'mult_0'], 'wb');
        fwrite(file_id, mult_0_data, 'double');
        fclose(file_id);

        file_id = fopen([file_path, 'mult_1'], 'wb');
        fwrite(file_id, mult_1_data, 'double');
        fclose(file_id);

        file_id = fopen([file_path, 'mult_2'], 'wb');
        fwrite(file_id, mult_2_data, 'double');
        fclose(file_id);

        file_id = fopen([file_path, 'mult_3'], 'wb');
        fwrite(file_id, mult_3_data, 'double');
        fclose(file_id);

        file_id = fopen([file_path, 'mult_4'], 'wb');
        fwrite(file_id, mult_4_data, 'double');
        fclose(file_id);

        file_id = fopen([file_path, 'diff_0'], 'wb');
        fwrite(file_id, diff_0_data, 'double');
        fclose(file_id);

        file_id = fopen([file_path, 'diff_1'], 'wb');
        fwrite(file_id, diff_1_data, 'double');
        fclose(file_id);

        file_id = fopen([file_path, 'diff_2'], 'wb');
        fwrite(file_id, diff_2_data, 'double');
        fclose(file_id);

        file_id = fopen([file_path, 'diff_3'], 'wb');
        fwrite(file_id, diff_3_data, 'double');
        fclose(file_id);

        file_id = fopen([file_path, 'diff_4'], 'wb');
        fwrite(file_id, diff_4_data, 'double');
        fclose(file_id);

    end

end

function data_decimal = read_data_from_sim(file_path, data_length, wl, fl)
    
    file_id   = fopen(file_path, 'r');
    data_char = fscanf(file_id, '%s');
    fclose(file_id);
    
    check_length = 32;
    mask         = zeros(1, check_length);
    for i = 1:round(length(data_char)/check_length)
        alpha_pos = isstrprop(data_char(1:check_length), 'alpha');
        if(isequal(alpha_pos, mask))
            break;
        else
            data_char(1) = [];
            j = 2;
            while (alpha_pos(j))
                data_char(1) = [];
                j = j + 1;
            end
        end
    end
    
    data_decimal = zeros(1, data_length);
    for i = 1:data_length
        a               = fi(0,1,wl, fl);
        a.bin           = data_char((i-1)*wl+1:i*wl);
        data_decimal(i) = double(a);
    end
    
end
