%Предварительно надо запустить программу с определением разрядности
%коэффициентов, закомментировать первую часть модели в Simulink  и
%раскомментировать вторую.

%определим диапазон амплитуд тестовых сигналов
%ограничением сверху выступает отсутствие переполнения на выходе
%интегратора
%значения амплитуд для одной частоты записываю в столбец

f                 = [0.01, 0.02, 0.04, 0.08, 0.17, 0.35];
wordlength        = 14;
fractional_length = 6;

max_amp = 2^(wordlength - fractional_length - 1) - 1 + 0.5*(1 - 0.5^(fractional_length))/(1 - 0.5);
lsb = 2^(-fractional_length);

amp = [];
for i = 1:length(f)
    divider = 2;
    for j = 1:10
        if j == 1
            amp(j,i) = max_amp/10^(ceil(dB_integrator_fp(find(freq == f(i))))/20)/2;
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
%%
%тест в режиме интегратора
ts = 1;
t = 0:ts:5/min(f);
Time = length(t)*ts;
ctrl = ones([length(t), 1]);
ctrl = [t', ctrl];
max_error_integr = [];
for i = 1:length(f)
    test_signal = sin(2*pi*f(i)*t')*(amp(:,i))';
    test_signal = [t', test_signal];
    sim("models_diff_integr.slx");
    error_data = ans.error;
    max_error_integr(end+1) = max(max(error_data));
end
%%
%определим диапазон амплитуд тестовых сигналов для дифференциатора
%значения амплитуд для одной частоты записываю в столбец

amp = [];
for i = 1:length(f)
    divider = 2;
    for j = 1:10
        if j == 1
            amp(j,i) = max_amp/10^(dB_diff_fp(find(freq == f(i)))/20);
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
%%
%тест в режиме дифференциатора
ts = 1;
t = 0:ts:5/min(f);
Time = length(t)*ts;
ctrl = zeros([length(t), 1]);
ctrl = [t', ctrl];
max_error_diff = [];
for i = 1:length(f)
    test_signal = sin(2*pi*f(i)*t')*(amp(:,i))';
    test_signal = [t', test_signal];
    sim("models_diff_integr.slx");
    error_data = ans.error;
    max_error_diff(end+1) = max(max(error_data));    
end
%%
disp("Integr error:")
max_error_integr
disp("Diff error:")
max_error_diff
graph = plot(f, max_error_integr/lsb, "DisplayName", "Максимальная ошибка в режиме интегратора");
graph.LineWidth = 1.5;
hold on
graph = plot(f, max_error_diff/lsb, "DisplayName", "Максимальная ошибка в режиме дифференциатора");
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