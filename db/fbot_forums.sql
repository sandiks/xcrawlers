--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.1
-- Dumped by pg_dump version 9.5.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: forums; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE forums (
    siteid integer NOT NULL,
    fid integer NOT NULL,
    name character varying,
    level integer,
    parent_fid integer,
    title character varying,
    "check" integer,
    bot_updated timestamp with time zone,
    descr character varying
);


ALTER TABLE forums OWNER TO postgres;

--
-- Data for Name: forums; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY forums (siteid, fid, name, level, parent_fid, title, "check", bot_updated, descr) FROM stdin;
4	200	community	0	\N	Сообщества	\N	\N	\N
4	300	teams	0	\N	Команды разработчиков	\N	\N	\N
4	400	code	0	\N	Программирование игр	\N	\N	\N
4	401	graphics	1	400	Графика	\N	\N	\N
4	402	2dgraph	1	400	2D графика и изометрия	\N	\N	\N
4	403	physics	1	400	Физика	\N	\N	\N
4	404	ai	1	400	Игровая логика и ИИ	\N	\N	\N
4	405	sound	1	400	Звук	\N	\N	\N
4	406	network	1	400	Сеть	\N	\N	\N
4	407	web	1	400	Веб	\N	\N	\N
4	408	common	1	400	Общее	\N	\N	\N
4	500	art	0	\N	Графический Дизайн	\N	\N	\N
4	501	modeling	1	500	Моделирование	\N	\N	\N
4	502	appreciatemodel	1	500	Оцените модель	\N	\N	\N
4	503	appreciateart	1	500	Оцените концепт	\N	\N	\N
4	504	common	1	500	Общее	\N	\N	\N
4	600	gamedesign	0	\N	Игровой Дизайн	\N	\N	\N
4	601	common	1	600	Общее	\N	\N	\N
4	602	leveldesign	1	600	Дизайн уровней	\N	\N	\N
4	603	scenarios	1	600	Сценарии игр	\N	\N	\N
4	700	industry	0	\N	Игровая индустрия	\N	\N	\N
4	701	management	1	700	Управление	\N	\N	\N
4	702	events	1	700	События	\N	\N	\N
4	703	marketing	1	700	Маркетинг	\N	\N	\N
4	800	sound	0	\N	Звук	\N	\N	\N
4	801	releases	1	800	Релизы	\N	\N	\N
4	802	appreciate	1	800	Оцените	\N	\N	\N
4	803	help	1	800	Помощь	\N	\N	\N
4	804	common	1	800	Общее	\N	\N	\N
4	900	mobile	0	\N	Мобильные платформы	\N	\N	\N
4	901	common	1	900	Общее	\N	\N	\N
4	1000	projects	0	\N	Проекты	\N	\N	\N
4	1001	appreciate	1	1000	Оцените	\N	\N	\N
4	1002	findteammembers	1	1000	Собираю команду	\N	\N	\N
4	1003	releases	1	1000	Релизы	\N	\N	\N
4	1004	tools	1	1000	Утилиты	\N	\N	\N
4	1005	contests	1	1000	Конкурсы	\N	\N	\N
4	1100	job	0	\N	Работа	\N	\N	\N
4	1101	vacancy	1	1100	Вакансии	\N	\N	\N
4	1102	once-only	1	1100	Разовая работа	\N	\N	\N
4	1103	resume	1	1100	Резюме	\N	\N	\N
4	1200	flame	0	\N	Флейм	\N	\N	\N
4	1201	gamedevelopment	1	1200	Разработка игр	\N	\N	\N
4	1202	programming	1	1200	Программирование	\N	\N	\N
4	1203	games	1	1200	Игры	\N	\N	\N
4	1204	proects	1	1200	ПроЭкты	\N	\N	\N
4	1205	hardware	1	1200	Железо	\N	\N	\N
4	1206	soft	1	1200	Софт	\N	\N	\N
4	1207	science	1	1200	Наука	\N	\N	\N
4	1208	movies	1	1200	Кинопродукция	\N	\N	\N
4	1209	regions	1	1200	Регионы	\N	\N	\N
4	1210	politics	1	1200	Политика	\N	\N	\N
4	1211	humor	1	1200	Юмор	\N	\N	\N
4	1212	common	1	1200	Общее	\N	\N	\N
4	1300	site	0	\N	Сайт	\N	\N	\N
4	1301	discussion	1	1300	Обсуждение	\N	\N	\N
2	99	dynamic	1	1000	dynamic	1	2016-03-08 19:30:45.698838+03	\N
4	100	job	0	\N	Персональные страницы	\N	\N	\N
2	27	philosophy	1	2000	philosophy	1	2016-03-08 19:30:46.361454+03	\N
5	138	\N	1	\N	Дороги, Аварии, Происшествия, ПДД, ГАИ, Законодательство	\N	\N	\N
5	64	\N	1	\N	ChillOut	\N	\N	\N
5	211	\N	1	\N	Недвижимость, строительство. Общие вопросы. Законодательство	\N	\N	\N
5	133	\N	1	\N	Фильмы, Телевидение, Книги, Музыка, Театр	\N	\N	\N
5	637	\N	1	\N	Легковые автомобили	\N	\N	\N
5	33	\N	1	\N	Мобильные телефоны	\N	\N	\N
5	171	\N	1	\N	Электронные книги	\N	\N	\N
5	185	\N	1	\N	Мониторы. Проекторы.	\N	\N	\N
5	515	\N	1	\N	Таможня. Граница. Таможенные и налоговые платежи	\N	\N	\N
5	271	\N	1	\N	Здоровье и Красота	\N	\N	\N
5	148	\N	1	\N	Жесткие диски	\N	\N	\N
5	641	\N	1	\N	Offtopic	\N	\N	\N
5	206	\N	1	\N	Активный отдых. Спорт. Секции.	\N	\N	\N
5	589	\N	1	\N	Родительский уголок	\N	\N	\N
3	160	multimedia	1	\N	Multimedia	1	2016-03-08 19:31:05.10851+03	\N
3	140	lor-source	1	\N	Lor-source	0	2015-11-12 02:12:57.408301+03	\N
3	20	desktop	1	\N	Desktop	1	2016-03-08 19:31:05.454465+03	\N
2	37	etude	1	2000	etude	1	2016-03-08 19:30:47.231148+03	\N
3	60	linux-org-ru	1	\N	Linux-org-ru	1	2016-03-08 19:31:05.855917+03	\N
3	180	science	1	\N	Science & Engineering	0	2015-11-12 02:12:57.845065+03	\N
2	26	asm	1	1000	asm	1	2016-03-08 19:30:45.332448+03	\N
2	3000	life	0	\N	Life	0	\N	\N
3	70	security	1	\N	Security	1	2016-03-08 19:31:06.229453+03	\N
3	80	linux-hardware	1	\N	Linux-hardware	1	2016-03-08 19:31:06.58457+03	\N
3	30	admin	1	\N	Admin	1	2016-03-08 19:31:07.011362+03	\N
3	90	talks	1	\N	Talks	1	2016-03-08 19:31:07.392938+03	\N
3	110	games	1	\N	Games	1	2016-03-08 19:31:07.774646+03	\N
3	130	club	1	\N	Клуб	1	2016-03-08 19:31:08.192869+03	\N
2	42	game	1	2000	game	1	2016-03-08 19:30:47.600421+03	\N
2	93	job.search	1	4000	job.search	1	2016-03-08 19:30:47.94947+03	\N
2	25	dotnet.web	1	2000	dotnet.web	1	2016-03-08 19:30:48.324639+03	\N
2	48	flame	1	3000	flame	1	2016-03-08 19:30:49.093224+03	\N
2	22	unix	1	2000	unix	1	2016-03-08 19:30:50.107169+03	\N
2	15	alg	1	2000	alg	1	2016-03-08 19:30:50.472203+03	\N
2	95	nemerle	1	1000	nemerle	1	2016-03-08 19:30:50.898998+03	\N
2	13	job	1	4000	job	1	2016-03-08 19:30:51.326317+03	\N
3	150	mobile	1	\N	Mobile	1	2016-03-08 19:31:03.954591+03	\N
2	1000	langs	0	\N	Langs	0	\N	\N
2	2000	technologies	0	\N	technologies	0	\N	\N
6	292	legal	1	\N	Юридические вопросы в ИТ	\N	\N	\N
6	30	dotnet	1	\N	WinForms, .Net Framework	\N	\N	\N
6	32	ado-linq-ef-orm	1	\N	ADO.NET, LINQ, Entity Framework, NHibernate, DAL, ORM	\N	\N	\N
6	33	wpf-silverlight	1	\N	WPF, Silverlight	\N	\N	\N
6	34	wcf-ws-remoting	1	\N	WCF, Web Services, Remoting	\N	\N	\N
6	40	delphi	1	\N	Delphi	\N	\N	\N
6	42	visual-basic	1	\N	Visual Basic	\N	\N	\N
6	43	programming	1	\N	Программирование	\N	\N	\N
6	45	powerbuilder	1	\N	PowerBuilder	\N	\N	\N
6	46	ms-office	1	\N	Microsoft Office	\N	\N	\N
6	47	sharepoint	1	\N	SharePoint	\N	\N	\N
6	48	xml	1	\N	XML, XSL, XPath, XQuery	\N	\N	\N
6	61	windows	1	\N	Windows	\N	\N	\N
5	32	\N	1	\N	Путешествия, Туризм и Отдых	\N	\N	\N
5	15	\N	1	\N	Автомобили: Эксплуатация, Обслуживание, Ремонт	\N	\N	\N
5	518	\N	1	\N	Одежда. Обувь. Аксессуары. Стиль	\N	\N	\N
5	135	\N	1	\N	Рестораны, Кафе, Клубы	\N	\N	\N
6	63	other-os	1	\N	Другие: Mac OS, PalmOS, BeOS, PocketPC	\N	\N	\N
6	70	sqlru	1	\N	Обсуждение нашего сайта	\N	\N	\N
6	71	question-answer	1	\N	Вопрос-Ответ	\N	\N	\N
5	443	\N	1	\N	Долевое строительство. ЖСПК	\N	\N	\N
5	11	\N	1	\N	Offtopic	\N	\N	\N
5	514	\N	1	\N	Финансы. Банки. Общие вопросы	\N	\N	\N
5	136	\N	1	\N	Бытовая техника	\N	\N	\N
5	46	\N	1	\N	Аудио/Видео	\N	\N	\N
5	12	\N	1	\N	Клубы Onliner'a	\N	\N	\N
5	516	\N	1	\N	Визовые вопросы. Иммиграция. Гражданство	\N	\N	\N
5	43	\N	1	\N	ФОТОтворчество	\N	\N	\N
5	61	\N	1	\N	Видеокамеры	\N	\N	\N
5	55	\N	1	\N	Право и законодательство. Общие вопросы	\N	\N	\N
5	9	\N	1	\N	Мобильные телефоны и планшеты	\N	\N	\N
5	14	\N	1	\N	Компьютеры и Интернет	\N	\N	\N
5	292	\N	1	\N	Планшеты	\N	\N	\N
5	41	\N	1	\N	Фотоаппараты	\N	\N	\N
5	898	\N	1	\N	Спорт	\N	\N	\N
5	139	\N	1	\N	Выбор и Покупка автомобиля, Автоновинки, Автодилеры, Кредит	\N	\N	\N
5	1	\N	1	\N	Служба поддержки пользователей (FAQ)	\N	\N	\N
5	356	\N	1	\N	Штативы	\N	\N	\N
5	622	\N	1	\N	Веломания	\N	\N	\N
5	31	\N	1	\N	Цифровая фототехника	\N	\N	\N
5	215	\N	1	\N	Медиаплееры	\N	\N	\N
5	517	\N	1	\N	Ремонт и отделка	\N	\N	\N
5	151	\N	1	\N	Холодильники	\N	\N	\N
5	259	\N	1	\N	Часы	\N	\N	\N
5	643	\N	1	\N	Apple. Mac. iPod. iPhone. iPad.	\N	\N	\N
5	264	\N	1	\N	Интернет-провайдеры	\N	\N	\N
5	595	\N	1	\N	Сантехника	\N	\N	\N
5	13	\N	1	\N	Автозвук, GPS навигация, Охранные системы и т.д.	\N	\N	\N
6	2	interbase	1	\N	Firebird, InterBaseIBExpert	\N	\N	\N
6	4	access	1	\N	Microsoft Access	\N	\N	\N
6	5	db2	1	\N	IBM DB2, WebSphere, IMS, U2, etc	\N	\N	\N
6	8	olap-dwh	1	\N	OLAP и DWH	\N	\N	\N
6	9	sybase	1	\N	Sybase ASA, ASE, IQ	\N	\N	\N
6	11	db-other	1	\N	Другие СУБД	\N	\N	\N
6	12	foxpro	1	\N	FoxPro, Visual FoxPro	\N	\N	\N
6	13	cache	1	\N	Caché	\N	\N	\N
6	15	nosql-bigdata	1	\N	NoSQL, Big Data	\N	\N	\N
6	21	db-comparison	1	\N	Сравнение СУБД	\N	\N	\N
6	22	db-design	1	\N	Проектирование БД	\N	\N	\N
6	24	erp-crm	1	\N	ERP и учетные системы1С	\N	\N	\N
6	25	testing-qa	1	\N	Тестирование и QA	\N	\N	\N
6	26	reporting	1	\N	Отчетные системы	\N	\N	\N
6	27	za-rubezhom	1	\N	Наши за рубежом	\N	\N	\N
6	28	certification	1	\N	Сертификация и обучение	\N	\N	\N
6	291	dev-management	1	\N	Управление процессом разработки ИС	\N	\N	\N
2	63	hardware	1	2000	hardware	1	2016-03-08 19:30:52.397955+03	\N
2	45	pda	1	2000	pda	1	2016-03-08 19:30:52.840401+03	\N
6	6	mysql	1	\N	MySQL	1	2016-03-08 19:31:13.039612+03	\N
6	10	informix	1	\N	Informix	0	\N	\N
3	170	midnight	1	\N	Midnight Commander	0	2015-11-12 02:13:02.774336+03	\N
2	83	flame.comp	1	3000	flame.comp	1	2016-03-08 19:30:53.3535+03	\N
3	40	linux-install	1	\N	Linux-install	1	2016-03-08 19:31:08.983515+03	\N
6	44	java	1	\N	Java	1	2016-03-08 19:31:13.56137+03	\N
2	59	job.offers	1	4000	job.offer	1	2016-03-08 19:30:53.921916+03	\N
2	10	java	1	1000	java	1	2016-03-08 19:30:55.053124+03	\N
2	40	shareware	1	4000	shareware	1	2016-03-08 19:30:55.550599+03	\N
6	7	postgresql	1	\N	PostgreSQL	0	\N	\N
2	92	job.offers.ea	1	4000	job.offer.ea	\N	\N	\N
2	12	web	1	2000	web	1	2016-03-08 19:30:55.991523+03	\N
3	10	general	1	\N	General	1	2016-03-08 19:31:09.750656+03	\N
3	120	web-development	1	\N	Web-development	1	2016-03-08 19:31:10.570326+03	\N
3	50	development	1	\N	Development	1	2016-03-08 19:31:10.974808+03	\N
2	6	db	1	2000	db	1	2016-03-08 19:30:57.215776+03	\N
6	62	linux	1	\N	Unix-системы	1	2016-03-08 19:31:14.051822+03	\N
6	41	cpp	1	\N	C++	1	2016-03-08 19:31:14.490515+03	\N
6	31	asp-net	1	\N	ASP.NET	1	2016-03-08 19:31:14.90868+03	\N
6	14	sqlite	1	\N	SQLite	1	2016-03-08 19:31:15.509474+03	\N
6	1	microsoft-sql-server	1	\N	Microsoft SQL Server	1	2016-03-08 19:31:15.953048+03	\N
6	240	job-offers	1	\N	вакансии	1	2016-03-08 19:31:16.662593+03	\N
6	23	job	1	\N	Работа	1	2016-03-08 19:31:17.788628+03	\N
6	29	hardware	1	\N	Hardware	1	2016-03-08 19:31:18.245094+03	\N
3	95	job	1	\N	job	1	2016-03-08 19:31:08.601497+03	\N
2	4000	job	0	\N	Jobs	0	\N	\N
6	16	pt	1	\N	Просто треп	1	2016-03-08 19:31:12.079636+03	\N
2	8	dotnet	1	1000	dotnet	1	2016-03-08 19:30:51.949152+03	\N
8	3	forum_3	1	1000	Сетевые пейджеры	1	\N	Андерграунд
8	5	forum_5	1	1000	Радиоэлектроника	1	\N	Андерграунд
8	56	forum_56	1	1000	Уязвимости и эксплойты	1	\N	Андерграунд
8	65	forum_65	1	1000	Вирусология, Ботнеты	1	\N	Андерграунд
8	70	forum_70	1	1000	Траффик, Спам, Загрузки	1	\N	Андерграунд
8	75	forum_75	1	1000	Анонимность и прокси	1	\N	Андерграунд
8	77	forum_77	1	1000	Криптография	1	\N	Андерграунд
8	100	forum_100	1	1000	Cracking/Reversring	1	\N	Андерграунд
8	120	forum_120	1	1000	Пакеры/Крипторы	1	\N	Андерграунд
7	1	matematika-obschie-voprosy-f1	0	0	Математика (общие вопросы)	1	\N	Математика
7	65	analiz-i-f65	1	27	Анализ-I	1	\N	\N
7	66	analiz-ii-f66	1	27	Анализ-II	1	\N	\N
7	67	veroyatnost-statistika-f67	1	27	Вероятность, статистика	1	\N	\N
7	68	vysshaya-algebra-f68	1	27	Высшая алгебра	1	\N	\N
7	69	diskretnaya-matematika-kombinatorika-teoriya-chisel-f69	1	27	Дискретная математика, комбинаторика, теория чисел	1	\N	\N
7	70	mat-logika-osnovaniya-matematiki-teoriya-algoritmov-f70	1	27	Мат. логика, основания математики, теория алгоритмов	1	\N	\N
7	27	pomogite-reshit-razobratsya-m-f27	0	0	Помогите решить / разобраться (М)	1	\N	Математика
2	73	cpp.applied	1	1000	cpp.applied	1	2016-03-08 19:30:57.713239+03	\N
2	11	network	1	2000	network	1	2016-03-08 19:30:58.183349+03	\N
2	33	humour	1	3000	humour	1	2016-03-08 19:30:58.694623+03	\N
7	26	olimpiadnye-zadachi-m-f26	0	0	Олимпиадные задачи (М)	\N	\N	Математика
7	36	internet-resursy-m-f36	0	0	Интернет-ресурсы (М)	\N	\N	Математика
7	52	matematicheskij-spravochnik-f52	0	0	Математический справочник	\N	\N	Математика
7	53	pomogite-reshit-razobratsya-f-f53	1	2	Помогите решить / разобраться (Ф)	\N	\N	\N
7	54	olimpiadnye-zadachi-f-f54	1	2	Олимпиадные задачи (Ф)	\N	\N	\N
7	37	internet-resursy-f-f37	1	2	Интернет-ресурсы (Ф)	\N	\N	\N
7	13	mehanika-i-tehnika-f13	0	0	Механика и Техника	\N	\N	Тематические обсуждения
7	14	biologiya-i-meditsina-f14	0	0	Биология и Медицина	\N	\N	Тематические обсуждения
7	77	internet-resursy-bim-f77	1	14	Интернет-ресурсы (БиМ)	\N	\N	\N
7	5	ekonomika-i-finansovaya-matematika-f5	0	0	Экономика и Финансовая математика	\N	\N	Тематические обсуждения
7	16	gumanitarnyj-razdel-f16	0	0	Гуманитарный раздел	\N	\N	Тематические обсуждения
7	83	diskussionnye-temy-gum-f83	1	16	Дискуссионные темы (Гум)	\N	\N	\N
7	15	mezhdistsiplinarnyj-razdel-f15	0	0	Междисциплинарный раздел	\N	\N	Тематические обсуждения
7	45	diskussionnye-temy-md-f45	1	15	Дискуссионные темы (Мд)	\N	\N	\N
7	61	voprosy-prepodavaniya-f61	0	0	Вопросы преподавания	\N	\N	Тематические обсуждения
7	9	rabota-foruma-f9	0	0	Работа форума	\N	\N	Форум dxdy.ru
7	6	lost-found-f6	0	0	Lost & found	\N	\N	Электронные книги
7	7	sozdanie-elektronnyh-knig-f7	0	0	Создание электронных книг	\N	\N	Электронные книги
7	20	testirovanie-f20	0	0	Тестирование	\N	\N	Флейм
2	34	life	1	3000	life	1	2016-03-08 19:31:00.755188+03	\N
2	74	decl	1	1000	decl	1	2016-03-08 19:31:02.430373+03	\N
7	71	chislennye-i-vychislitelnye-metody-optimizatsiya-f71	1	27	Численные и вычислительные методы, оптимизация	1	\N	\N
7	72	shkolnaya-algebra-f72	1	27	Школьная алгебра	1	\N	\N
7	73	geometriya-f73	1	27	Геометрия	1	\N	\N
7	74	prochee-f74	1	27	Прочее	1	\N	\N
7	29	diskussionnye-temy-f-f29	1	2	Дискуссионные темы (Ф)	1	\N	\N
7	90	astronomiya-f90	0	0	Астрономия	1	\N	Тематические обсуждения
7	3	computer-science-f3	0	0	Computer Science	1	\N	Тематические обсуждения
7	50	programmirovanie-f50	1	3	Программирование	1	\N	\N
7	42	kompyuternye-seti-i-web-tehnologii-f42	1	3	Компьютерные сети и Web-технологии	1	\N	\N
8	2	forum_2	1	1000	Защита и взлом	1	\N	Андерграунд
7	41	hardware-f41	1	3	Hardware	1	\N	\N
7	40	software-f40	1	3	Software	1	\N	\N
7	39	okolonauchnyj-soft-f39	1	3	Околонаучный софт	1	\N	\N
7	38	internet-resursy-cs-f38	1	3	Интернет-ресурсы (CS)	1	\N	\N
7	33	texnicheskie-obsuzhdeniya-f33	1	3	TeXнические обсуждения	1	\N	\N
7	88	olimpiadnye-zadachi-cs-f88	1	3	Олимпиадные задачи (CS)	1	\N	\N
7	4	himiya-f4	0	0	Химия	1	\N	Тематические обсуждения
7	10	svobodnyj-polyot-f10	0	0	Свободный полёт	1	\N	Флейм
7	30	besedy-na-okolonauchnye-temy-f30	1	10	Беседы на околонаучные темы	1	\N	\N
7	31	yumor-pozdravleniya-shodki-f31	1	10	Юмор, поздравления, сходки	1	\N	\N
7	89	zagadki-golovolomki-rebusy-f89	1	10	Загадки, головоломки, ребусы	1	\N	\N
7	2	fizika-f2	0	0	Физика	1	\N	Тематические обсуждения
7	28	diskussionnye-temy-m-f28	0	0	Дискуссионные темы (М)	1	\N	Математика
2	84	flame.politics	1	3000	flame.politics	1	2016-03-08 19:31:03.271527+03	\N
7	62	velikaya-teorema-ferma-f62	1	28	Великая теорема Ферма	1	\N	\N
2	28	tools	1	1000	tools	1	2016-03-08 19:31:00.074431+03	\N
6	50	php-perl	1	\N	PHP, Perl, Python	1	2016-03-08 19:31:18.645196+03	\N
6	51	html-javascript-css	1	\N	HTML, JavaScript, VBScript, CSSСерверный JavaScript (node.js, ringo, nitro, sling)	1	2016-03-08 19:31:19.04546+03	\N
6	3	oracle	1	\N	OracleOracle APEX	1	2016-03-08 19:31:20.226021+03	\N
\.


--
-- Name: forums_prkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY forums
    ADD CONSTRAINT forums_prkey PRIMARY KEY (siteid, fid);


--
-- PostgreSQL database dump complete
--

