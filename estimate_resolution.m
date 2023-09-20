%Начальные данные

Num = [-0.016686934099368,
       0.195507800433580,
       -0.394962749734687,
       0.433866959174206,
       0.597244731023441
       ];
Num = [Num', -fliplr(Num')];

b_Tick            = [0.3584, 1.2832, 0.3584];
a_Tick            = [1, 0, -1];
freq              = 0.01:0.0001:0.35;
ts                = 1;
resolution_integr = ones([1,3]);

%limit - ограничение ошибки по заданию, размерность - дБ

limit = 0.1;
%%
%Поиск разрядности для числа 0,358
% Считаем, что b_Tick(1) и b_Tick(3) одно и то же число, так как в таком
% случае ФЧХ линейна
%b_Tick(2) оставляем double
%max_resolution - ограничение по максиамльной разрядности, чтобы уменшить
%время моделирования

max_error          = [];
order              = 0:2;
mult               = exp(-1i * 2 * pi * order' * freq * ts);
transfer_func_Tick = (b_Tick * mult)./(a_Tick * mult);
dB_func_Tick       = 20 * log10(abs(transfer_func_Tick));
max_resolution     = 20;
for i = 1:max_resolution
    dB_invest_func = 20 * log10(abs([double(fi(b_Tick(1), 0, i + 1, i)), b_Tick(2), double(fi(b_Tick(3),0,i + 1,i))] * mult ./ (a_Tick * mult)));
    max_error(end+1) = max(abs(dB_invest_func - dB_func_Tick));   
end
graph = plot(1:max_resolution, max_error);
graph.LineWidth = 1.5;
xlabel("Разрядность, бит")
ylabel("Максимальная ошибка, дБ")
ax = gca;
set(get(ax,'YLabel'),'Rotation',90);
ax.FontName = "Times New Roman";
ax.FontSize = 10;
grid on
%%
%Выбираем разрядность коэффициентов 1 и 3

pos_res              = find(max_error < limit);
resolution_integr(1) = pos_res(1);
resolution_integr(3) = pos_res(1);
%%
%Ищем второй коэффициент, фиксируем разрядность первого и второго
max_error = [];
for i = 1:max_resolution
    dB_invest_func = 20 * log10(abs([double(fi(b_Tick(1), 0, resolution_integr(1) + 1, resolution_integr(1))), double(fi(b_Tick(2), 0, i + 1, i)), double(fi(b_Tick(3),0,resolution_integr(3) + 1,resolution_integr(3)))]*mult./(a_Tick*mult)));
    max_error(end+1) = max(abs(dB_invest_func - dB_func_Tick));  
end
graph = plot(1:max_resolution, max_error);
graph.LineWidth = 1.5;
xlabel("Разрядность, бит")
ylabel("Максимальная ошибка, дБ")
ax = gca;
set(get(ax,'YLabel'),'Rotation',90);
ax.FontName = "Times New Roman";
ax.FontSize = 10;
grid on
%%
%Выбираем разрядность коэффициента 2
pos_res              = find(max_error < limit);
resolution_integr(2) = pos_res(1);
%%
%Отображение ошибки модели интегратора
coeff_integrator = b_Tick;
for i = 1:length(b_Tick)
    coeff_integrator(i) = double(fi(b_Tick(i), 1, resolution_integr(i) + 2, resolution_integr(i)));
end
dB_integrator_fp = 20 * log10(abs(coeff_integrator * mult./(a_Tick * mult)));
error_integrator = abs(dB_integrator_fp - dB_func_Tick);
graph = plot(freq, error_integrator);
graph.LineWidth = 1.5;
xlabel("Нормированная частота")
ylabel("Ошибка модели с фиксированной точкой, дБ")
ax = gca;
set(get(ax,'YLabel'),'Rotation',90);
ax.FontName = "Times New Roman";
ax.FontSize = 10;
grid on
%%
%Далее исследуем коэффициенты дифференциатора
%Методы все те же самые
order              = 0:9;
ts                 = 1;
resolution_diff    = zeros([1, order(end) + 1]);
mult               = exp(-1i * 2 * pi * order' * freq * ts);
transfer_func_diff = Num * mult;
dB_func_diff       = 20 * log10(abs(transfer_func_diff));
max_resolution     = 20;
coeff              = Num;
for j = 1:(order(end)+1)/2
    max_error = [];
    if j > 1
        coeff(j-1)     = double(fi(coeff(j-1), 1, resolution_diff(j-1) + 2, resolution_diff(j-1)));
        coeff(end-j+2) = double(fi(coeff(end-j+2), 1, resolution_diff(j-1) + 2, resolution_diff(j-1)));
    end
    for i = 1:max_resolution
        coeff(j)         = double(fi(Num(j), 1, i+2, i));
        coeff(end-j+1)   = double(fi(Num(end-j+1), 1, i+2, i));
        dB_invest_func   = 20*log10(abs(coeff*mult));
        max_error(end+1) = max(abs(dB_invest_func - dB_func_diff));
    end
    figure(j)
    graph = plot(1:max_resolution, max_error);
    graph.LineWidth = 1.5;
    xlabel("Разрядность, бит")
    ylabel("Максимальная ошибка, дБ")
    ax = gca;
    set(get(ax,'YLabel'),'Rotation',90);
    ax.FontName = "Times New Roman";
    ax.FontSize = 10;
    grid on
    pos_res                  = find(max_error < limit);
    resolution_diff(j)       = pos_res(1);
    resolution_diff(end-j+1) = pos_res(1);
end
%%
%Покажем распределение ошибки вдоль полосы для дифференциатора
dB_diff_fp = 20 * log10(abs(coeff * mult));
error_diff = abs(dB_diff_fp - dB_func_diff);

graph = plot(freq, error_diff);
graph.LineWidth = 1.5;
xlabel("Нормированная частота")
ylabel("Ошибка модели с фиксированной точкой, дБ")
ax = gca;
set(get(ax,'YLabel'),'Rotation',90);
ax.FontName = "Times New Roman";
ax.FontSize = 10;
grid on
%%
%график совместный с указанием линии критерия
graph = plot(freq, error_diff, 'DisplayName', 'Ошибка для модели дифференциатора');
graph.LineWidth = 1.5;
hold on
graph = plot(freq, error_integrator, 'DisplayName', 'Ошибка для модели интегратора');
graph.LineWidth = 1.5;
graph = plot(linspace(0,0.35, 2), limit*ones([1,2]), 'r--', 'DisplayName', 'Предельная ошибки');
graph.LineWidth = 1.5;
xlabel("Нормированная частота")
ylabel("Ошибка модели с фиксированной точкой, дБ")
ax = gca;
set(get(ax,'YLabel'),'Rotation',90);
ax.FontName = "Times New Roman";
ax.FontSize = 10;
grid on
legend('boxoff')
ylim([0, 1.2*limit])
hold off