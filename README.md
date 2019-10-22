# AndroidRank

## Usage

```morbo app_follow_test/script/app_follow_test```

## Task
### Android Rank App

#### Описание 

Нужно разработать простое веб приложение по просмотру данных с AnroidRank. Задача включает в себя написание парсера сервиса и проектирование приложение используя (Mojolicious, Semantic, jQuery).

#### 1. Модуль AndroidRank.pm

* Использовать Mojo::Base
* Парсинг html с помощью Mojo::DOM
* Get запросы Mojo::UserAgent
* JSON
* Отдельных модулей кроме JSON и Mojolicious не использовать

#### 1.1 метод suggest(q => ‘uber’)

* вход: `q => ‘uber’`
* выход:  массив: `{ ext_id => ‘com.ubercab’, title => ‘Uber’ }`

На сайте http://www.androidrank.org/ в верхнем правом углу есть ajax suggest. 

#### 1.2 метод get_app_details(ext_id => ‘com.ubercab’)

* вход:  `ext_id => ‘com.ubercab’`
* выход: хэш с данными по приложению:

```
title       => 'Uber',
artist_id   => '7908612043055486674',
artist_name => 'Uber Technologies, Inc',
short_text  => 'Android application Uber developed by Uber Technologies, Inc. is listed under category Maps & Navigation. According to Google Play Uber achieved more than 100,000,000 installs. Uber currently has 1,419,221 ratings with average rating value of 4.311. The current percentage of ratings achieved in last 30 days is 11.3%, percentage of ratings achieved in last 60 days is 23.07%. Uber has the current market possition #251 by number of ratings. A sample of the market history data for Uber can be found below.',
icon        => 'https://lh3.googleusercontent.com/aMoTzec746RIY9GFOKMjipqBShsKos_KxeDtS59tRp4-ePCpGqW2bS-ySyUEL6q3gkA=w64',
```

```
app_info => {
	...
},

app_installs => {
	...
},

rating_values => {
	...
},

rating_score => {
	...
},

country_rankings => {
	br => 1,
	...
},
```

Страница: http://www.androidrank.org/application/uber/com.ubercab?hl=en
Нужна только шапка. 


#### 2. Web приложение

Используй http://semantic-ui.com/ для интерфейса страницы, jQuery для ajax. 

Апп должен быть сделан на Mojolicious. UI должен быть удобным.

Сделать аналогичный suggest как в androidrank, спользуя библиотеку AdroidRank.pm, показывать возможные варианты. Форму поиска сделай по центру экрана сверху. 

По клику на один из возможных вариантов делать ajax запрос к AnroidRank->app(ext_id => xxx) 

И ниже поиска сформировать карточку с этим приложением. 

Плюс рядом с поиском нужна кнопка reset, которая появляется когда есть приложение. 

#### 3. Примечание

Код прогнать через perlcritic,

По стилю использовать tab

Готовое приложение прислать ссылкой на исходнике на Github/Bitbucket и ссылкой на работающее демо.
