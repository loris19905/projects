%% Параметры управления скриптом

MAKE_PLOT         = 0;
FILTER_MODE       = 'integrator'; % 'integrator', 'differentiator', 'both'
SINGLE_TONE_TEST  = 1;                      % Если 1, то подается 1 амлитуда в модель; если 0, то моделируется весь диапазон значений

%% Начальные данные

INPUT_FREQ_VECTOR = 1/8;
AMPLITUDE         = 10;

BANDWIDTH         = 0.35;
FREQ_RANGE        = 0.01:0.0001:BANDWIDTH;

WORDLENGTH        = 14;
FRACTIONAL_LENGTH = 6;

MODEL_DATA_FILE_NAME = 'model_data';
DATA_FILE_PATH       = '..\data\'; 
INPUT_DATA_FILE_NAME = 'data_in.txt';

FS   = 1;
N    = 128; 
t    = 0:1/FS:(N-1)/min(INPUT_FREQ_VECTOR);
Time = length(t)/FS;

%% Тест интегратора

%Предварительно надо запустить программу с определением разрядности
%коэффициентов, закомментировать первую часть модели в Simulink  и
%раскомментировать вторую.

%определим диапазон амплитуд тестовых сигналов
%ограничением сверху выступает отсутствие переполнения на выходе
%интегратора
%значения амплитуд для одной частоты записываю в столбец

if strcmp(FILTER_MODE, 'integrator') || strcmp(FILTER_MODE, 'both')
    
    max_amp = 2^(WORDLENGTH - FRACTIONAL_LENGTH - 1) - 1 + 0.5*(1 - 0.5^(FRACTIONAL_LENGTH))/(1 - 0.5);
    lsb = 2^(-FRACTIONAL_LENGTH);
    
    if (SINGLE_TONE_TEST)
        amp = AMPLITUDE;
    else
        amp = [];
        for i = 1:length(INPUT_FREQ_VECTOR)
            divider = 2;
            for j = 1:10
                if j == 1
                    amp(j,i) = max_amp/10^(ceil(dB_integrator_fp(find(freq == INPUT_FREQ_VECTOR(i))))/20)/2;
                    if amp(j,i) > max_amp/2
                        amp(j,i) = max_amp/2;
                    end
                    
                    while amp(j,i)/(divider^9) < lsb
                        divider = divider * 0.9;
                    end
                else
                    amp(j,i) = amp(j-1,i)/divider;
                end
            end
        end
    end

    ctrl = ones([length(t), 1]);
    ctrl = [t', ctrl];
    max_error_integr = [];
    for i = 1:length(INPUT_FREQ_VECTOR)
        test_signal = sin(2*pi*INPUT_FREQ_VECTOR(i)*t')*(amp(:,i))';
        test_signal = [t', test_signal];
        sim("models_diff_integr.slx");
        error_data = ans.error;
        max_error_integr(end+1) = max(max(error_data));
    end

    file_id = fopen([DATA_FILE_PATH, MODEL_DATA_FILE_NAME, '_integrator'], 'wb');
    fwrite(file_id, ans.fp_out_signal.data, 'double');
    fclose(file_id);
    
    if (SINGLE_TONE_TEST)
        file_id     = fopen([DATA_FILE_PATH, INPUT_DATA_FILE_NAME], 'w');
        test_signal = round(test_signal(:,2) * 2^FRACTIONAL_LENGTH);
        for i = 1:N
            bin_repr = dec2bin(test_signal(i));
            if length(bin_repr) < WORDLENGTH
                zero_num = WORDLENGTH - length(bin_repr); 
                for j = 1:zero_num
                    if (test_signal(i) < 0)
                        bin_repr = ['1', bin_repr];
                    else
                        bin_repr = ['0', bin_repr];
                    end
                end
            elseif length(bin_repr) > WORDLENGTH
                delete_bits_num             = length(bin_repr) - WORDLENGTH;
                bin_repr(1:delete_bits_num) = [];
            end
            fprintf(file_id, '%s\n', bin_repr);
        end
    end
end

%% Тест дифференциатора
%определим диапазон амплитуд тестовых сигналов для дифференциатора
%значения амплитуд для одной частоты записываю в столбец
if strcmp(FILTER_MODE, 'differentiator') || strcmp(FILTER_MODE, 'both')

    if (SINGLE_TONE_TEST)
        amp = AMPLITUDE;
    else
        amp = [];
        for i = 1:length(INPUT_FREQ_VECTOR)
            divider = 2;
            for j = 1:10
                if j == 1
                    amp(j,i) = max_amp/10^(dB_diff_fp(find(freq == INPUT_FREQ_VECTOR(i)))/20);
                    if amp(j,i) > max_amp
                        amp(j,i) = max_amp;
                    end
                    while amp(j,i)/(divider^9) < lsb
                        divider = divider*0.9;
                    end
                else
                    amp(j,i) = amp(j-1,i)/divider;
                end
            end
        end
    end

    ctrl = zeros([length(t), 1]);
    ctrl = [t', ctrl];
    max_error_diff = [];
    for i = 1:length(INPUT_FREQ_VECTOR)
        test_signal = sin(2*pi*f(i)*t')*(amp(:,i))';
        test_signal = [t', test_signal];
        sim("models_diff_integr.slx");
        error_data = ans.error;
        max_error_diff(end+1) = max(max(error_data));    
    end

    file_id = fopen([DATA_FILE_PATH, MODEL_DATA_FILE_NAME, '_differentiator'], 'wb');
    fwrite(file_id, ans.fp_out_signal.data);
    fclose(file_id);

    if (SINGLE_TONE_TEST)
        file_id     = fopen([DATA_FILE_PATH, INPUT_DATA_FILE_NAME], 'w');
        test_signal = round(test_signal * 2^FRACTIONAL_LENGTH);
        for i = 1:N
            bin_repr = dec2bin(test_signal(i));
            if length(bin_repr) < WORDLENGTH
                zero_num = WORDLENGTH - length(bin_repr); 
                for j = 1:zero_num
                    if (test_signal(i) < 0)
                        bin_repr = ['1', bin_repr];
                    else
                        bin_repr = ['0', bin_repr];
                    end
                end
            end
            fprintf(file_id, '%s\n', bin_repr);
        end
    end
end

%% Вывод вектора ошибок

if (MAKE_PLOT)
    disp("Integr error:")
    max_error_integr
    disp("Diff error:")
    max_error_diff
    graph = plot(INPUT_FREQ_VECTOR, max_error_integr/lsb, "DisplayName", "Максимальная ошибка в режиме интегратора");
    graph.LineWidth = 1.5;
    hold on
    graph = plot(INPUT_FREQ_VECTOR, max_error_diff/lsb, "DisplayName", "Максимальная ошибка в режиме дифференциатора");
    graph.LineWidth = 1.5;
    xlabel("Нормированная частота")
    ylabel("Ошибка, МЗР")
    ax = gca;
    set(get(ax,'YLabel'),'Rotation',90);
    ax.FontName = "Times New Roman";
    ax.FontSize = 10;
    grid on
    legend("boxoff")
    ylim([0, 4])
    hold off
end