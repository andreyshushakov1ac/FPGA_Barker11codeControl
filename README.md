Altera DE2-115


 УПРАВЛЕНИЕ ГРОМКОСТЬЮ, ЧАСТОТОЙ И СДВИГОМ ПО ВРЕМЕНИ 
 11 БИТНОГО СИНУСОИДАЛЬНОГО КОДА БАРКЕРА + ЕСТЬ ВАРИАНТ ИМПУЛЬСНОГО 
 С ЗАДЕРЖКАМИ [...], [...] ИЛИ [...] периода ([...] периода постоян, далее периоды, когда сигнал в нуле)

Изначальный синус с частотой около 1кГц 
Двоичный код баркера с частотой 250Гц (т.е. 4 колебания синуса на бит Баркера)
----
ROM_out1: Выводит код 11 битный Баркера, заполненный синусоидами (без манипуляций с частотой на 1 бит 
баркера приходиться один период синусоиды). На фронте и спаде баркер-кода происходи сдвиг
фазы на 180 градусов. 
----
Есть варианты ROM_out1 (нужно раскомментировать), когда есть , когда после каждой секунды 
сигнал равен 0 на протяжении 1.5, 2 и 4 секунд (можно выбрать в первом в этой программе 
always-блоке)
----
ROM_out - это исходный синус из файла sine16by256.mif, записанный в ROM:
16битный синус на 2048 отсчётов, амплитуда намеренно уменьшена в 3 раза, чтобы была возможность
реализовать умножитель отсчётов
----

11битный Баркер-код (11100010010) посмотреть на осц-фе можно через GPIO: 
1ая левая сверху дата, 6ая сверху правая- земля 

Если держишь  key2 или key3 одну секунду, то частота увеличивается
на +-FREQ_STEP соответственно

key1 при нажатии увелчивает громкость (умножитель отсчётов):  1 нажатие - в 2 раза; 
2 нажатия - в 3 раза; 3 нажатия - в 1 раз

key0 - reset

sw0 -  при любом переключении - сдвиг фазы на 180*



(изначально период=слово, где слово - это бит баркера)
