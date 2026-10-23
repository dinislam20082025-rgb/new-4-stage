CREATE DATABASE EmiasDB;
GO
USE EmiasDB;
GO
CREATE SCHEMA med;
GO

CREATE TABLE med.Поликлиника (
    ID            INT IDENTITY(1,1) PRIMARY KEY,
    Наименование  NVARCHAR(150) NOT NULL,
    Адрес         NVARCHAR(200) NULL,
    Телефон       NVARCHAR(20)  NULL
);

CREATE TABLE med.Специализация (
    ID            INT IDENTITY(1,1) PRIMARY KEY,
    Наименование  NVARCHAR(100) NOT NULL UNIQUE,
    Активна       BIT           NOT NULL DEFAULT 1
);

CREATE TABLE med.Пациент (
    ID             INT IDENTITY(1,1) PRIMARY KEY,
    ФИО            NVARCHAR(150) NOT NULL,
    ДатаРождения   DATE          NOT NULL,
    Пол            CHAR(1)       NOT NULL CHECK (Пол IN ('М','Ж')),
    ПолисОМС       NVARCHAR(16)  NOT NULL UNIQUE,
    СНИЛС          NVARCHAR(14)  NULL UNIQUE,
    Телефон        NVARCHAR(20)  NULL
);

CREATE TABLE med.Лекарство (
    ID             INT IDENTITY(1,1) PRIMARY KEY,
    Наименование   NVARCHAR(150) NOT NULL,
    ФормаВыпуска   NVARCHAR(50)  NOT NULL,
    Цена           DECIMAL(10,2) NOT NULL CHECK (Цена > 0)
);

CREATE TABLE med.Поставщик (
    ID             INT IDENTITY(1,1) PRIMARY KEY,
    Наименование   NVARCHAR(150) NOT NULL,
    Телефон        NVARCHAR(20)  NULL
);

CREATE TABLE med.Врач (
    ID                INT IDENTITY(1,1) PRIMARY KEY,
    ФИО               NVARCHAR(150) NOT NULL,
    СпециализацияID   INT NOT NULL,
    ПоликлиникаID     INT NOT NULL,
    Кабинет           NVARCHAR(10) NULL,
    CONSTRAINT FK_Врач_Специализация FOREIGN KEY (СпециализацияID) REFERENCES med.Специализация(ID),
    CONSTRAINT FK_Врач_Поликлиника   FOREIGN KEY (ПоликлиникаID)   REFERENCES med.Поликлиника(ID)
);

CREATE TABLE med.Поставка (
    ID                INT IDENTITY(1,1) PRIMARY KEY,
    ПоставщикID       INT NOT NULL,
    Дата              DATE NOT NULL DEFAULT GETDATE(),
    НомерНакладной    NVARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT FK_Поставка_Поставщик FOREIGN KEY (ПоставщикID) REFERENCES med.Поставщик(ID)
);

CREATE TABLE med.Расписание (
    ID               INT IDENTITY(1,1) PRIMARY KEY,
    ВрачID           INT NOT NULL,
    Дата             DATE NOT NULL,
    ВремяНачала      TIME NOT NULL,
    ВремяОкончания   TIME NOT NULL,
    CONSTRAINT FK_Расписание_Врач FOREIGN KEY (ВрачID) REFERENCES med.Врач(ID) ON DELETE CASCADE,
    CONSTRAINT CHK_Расписание_Интервал CHECK (ВремяОкончания > ВремяНачала)
);

CREATE TABLE med.Запись (
    ID            INT IDENTITY(1,1) PRIMARY KEY,
    ПациентID     INT NOT NULL,
    ВрачID        INT NOT NULL,
    Дата          DATE NOT NULL,
    Время         TIME NOT NULL,
    Статус        NVARCHAR(20) NOT NULL DEFAULT 'активна' CHECK (Статус IN ('активна','отменена','завершена')),
    CONSTRAINT FK_Запись_Пациент FOREIGN KEY (ПациентID) REFERENCES med.Пациент(ID),
    CONSTRAINT FK_Запись_Врач    FOREIGN KEY (ВрачID)    REFERENCES med.Врач(ID) ON DELETE CASCADE,
    CONSTRAINT UQ_Запись_Врач_Дата_Время UNIQUE (ВрачID, Дата, Время)
);

CREATE TABLE med.ПозицияПоставки (
    ID            INT IDENTITY(1,1) PRIMARY KEY,
    ПоставкаID    INT NOT NULL,
    ЛекарствоID   INT NOT NULL,
    Количество    INT NOT NULL CHECK (Количество > 0),
    ЦенаЗакупки   DECIMAL(10,2) NOT NULL CHECK (ЦенаЗакупки > 0),
    CONSTRAINT FK_Позиция_Поставка  FOREIGN KEY (ПоставкаID)  REFERENCES med.Поставка(ID) ON DELETE CASCADE,
    CONSTRAINT FK_Позиция_Лекарство FOREIGN KEY (ЛекарствоID) REFERENCES med.Лекарство(ID),
    CONSTRAINT UQ_Позиция_Поставка_Лекарство UNIQUE (ПоставкаID, ЛекарствоID)
);

CREATE TABLE med.Медкарта (
    ID            INT IDENTITY(1,1) PRIMARY KEY,
    ЗаписьID      INT NOT NULL UNIQUE,
    Жалобы        NVARCHAR(MAX) NULL,
    Заключение    NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Медкарта_Запись FOREIGN KEY (ЗаписьID) REFERENCES med.Запись(ID) ON DELETE CASCADE
);

CREATE TABLE med.Диагноз (
    ID            INT IDENTITY(1,1) PRIMARY KEY,
    МедкартаID    INT NOT NULL,
    КодМКБ10      NVARCHAR(10) NOT NULL,
    Наименование  NVARCHAR(200) NOT NULL,
    CONSTRAINT FK_Диагноз_Медкарта FOREIGN KEY (МедкартаID) REFERENCES med.Медкарта(ID) ON DELETE CASCADE
);

CREATE TABLE med.АудитИзменений (
    ID             INT IDENTITY(1,1) PRIMARY KEY,
    Таблица        NVARCHAR(100) NOT NULL,
    Операция       NVARCHAR(10)  NOT NULL,
    КлючЗаписи     INT           NULL,
    Данные         NVARCHAR(MAX) NULL,
    Пользователь   NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    ДатаИзменения  DATETIME2     NOT NULL DEFAULT GETDATE()
);

CREATE TABLE med.ЖурналОшибок (
    ID          INT IDENTITY(1,1) PRIMARY KEY,
    Процедура   NVARCHAR(200) NOT NULL,
    Сообщение   NVARCHAR(4000) NOT NULL,
    НомерОшибки INT NULL,
    ДатаОшибки  DATETIME NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_АудитИзменений_Таблица_Дата ON med.АудитИзменений(Таблица, ДатаИзменения DESC);
CREATE INDEX IX_Пациент_ФИО ON med.Пациент(ФИО);
CREATE INDEX IX_Расписание_Врач_Дата ON med.Расписание(ВрачID, Дата);
CREATE INDEX IX_Запись_Врач_Дата ON med.Запись(ВрачID, Дата);
CREATE INDEX IX_Запись_Пациент_Дата ON med.Запись(ПациентID, Дата);
CREATE INDEX IX_Запись_Статус ON med.Запись(Статус);
CREATE INDEX IX_Врач_Специализация ON med.Врач(СпециализацияID);
CREATE INDEX IX_Поставка_Дата ON med.Поставка(Дата);
CREATE INDEX IX_ПозицияПоставки_Поставка ON med.ПозицияПоставки(ПоставкаID);
CREATE INDEX IX_Диагноз_Медкарта ON med.Диагноз(МедкартаID);
GO

CREATE OR ALTER VIEW med.v_РасписаниеВрача AS
SELECT р.ID AS РасписаниеID, в.ФИО AS Врач, сп.Наименование AS Специализация, п.Наименование AS Поликлиника, р.Дата, р.ВремяНачала, р.ВремяОкончания, з.ID AS ЗаписьID, пац.ФИО AS Пациент, з.Статус
FROM med.Расписание р
JOIN med.Врач в ON в.ID = р.ВрачID
JOIN med.Специализация сп ON сп.ID = в.СпециализацияID
JOIN med.Поликлиника п ON п.ID = в.ПоликлиникаID
LEFT JOIN med.Запись з ON з.ВрачID = р.ВрачID AND з.Дата = р.Дата
LEFT JOIN med.Пациент пац ON пац.ID = з.ПациентID;
GO

CREATE OR ALTER VIEW med.v_ЗагрузкаВрача AS
SELECT в.ID AS ВрачID, в.ФИО AS Врач, сп.Наименование AS Специализация, з.Дата, COUNT(з.ID) AS ВсегоТалонов, SUM(CASE WHEN з.Статус = 'активна' THEN 1 ELSE 0 END) AS Активных, SUM(CASE WHEN з.Статус = 'отменена' THEN 1 ELSE 0 END) AS Отменённых, SUM(CASE WHEN з.Статус = 'завершена' THEN 1 ELSE 0 END) AS Завершённых
FROM med.Врач в
JOIN med.Специализация сп ON сп.ID = в.СпециализацияID
LEFT JOIN med.Запись з ON з.ВрачID = в.ID
GROUP BY в.ID, в.ФИО, сп.Наименование, з.Дата;
GO

CREATE OR ALTER VIEW med.v_ДиагнозыПациента AS
SELECT пац.ID AS ПациентID, пац.ФИО AS Пациент, пац.ПолисОМС, з.Дата AS ДатаПриёма, в.ФИО AS Врач, сп.Наименование AS Специализация, д.КодМКБ10, д.Наименование AS Диагноз
FROM med.Пациент пац
JOIN med.Запись з ON з.ПациентID = пац.ID
JOIN med.Медкарта м ON м.ЗаписьID = з.ID
JOIN med.Диагноз д ON д.МедкартаID = м.ID
JOIN med.Врач в ON в.ID = з.ВрачID
JOIN med.Специализация сп ON сп.ID = в.СпециализацияID;
GO

CREATE OR ALTER VIEW med.v_РасходыНаЛекарства AS
SELECT п.Дата, пост.Наименование AS Поставщик, л.Наименование AS Лекарство, пп.Количество, пп.ЦенаЗакупки, пп.Количество * пп.ЦенаЗакупки AS Сумма
FROM med.Поставка п
JOIN med.Поставщик пост ON пост.ID = п.ПоставщикID
JOIN med.ПозицияПоставки пп ON пп.ПоставкаID = п.ID
JOIN med.Лекарство л ON л.ID = пп.ЛекарствоID;
GO

CREATE OR ALTER FUNCTION med.fn_Пациент_Возраст (@ДатаРождения DATE) RETURNS INT AS
BEGIN
    IF @ДатаРождения IS NULL OR @ДатаРождения > CAST(GETDATE() AS DATE) RETURN NULL;
    DECLARE @Возраст INT = DATEDIFF(YEAR, @ДатаРождения, GETDATE());
    IF (MONTH(@ДатаРождения) > MONTH(GETDATE())) OR (MONTH(@ДатаРождения) = MONTH(GETDATE()) AND DAY(@ДатаРождения) > DAY(GETDATE()))
        SET @Возраст = @Возраст - 1;
    RETURN @Возраст;
END;
GO

CREATE OR ALTER FUNCTION med.fn_ФИО_Сокращённое (@ФИО NVARCHAR(150)) RETURNS NVARCHAR(150) AS
BEGIN
    IF @ФИО IS NULL OR LEN(LTRIM(RTRIM(@ФИО))) = 0 RETURN NULL;
    DECLARE @ФИООбр NVARCHAR(150) = LTRIM(RTRIM(@ФИО)), @ч1 INT, @ч2 INT;
    SET @ч1 = CHARINDEX(' ', @ФИООбр);
    IF @ч1 = 0 RETURN @ФИООбр;
    SET @ч2 = CHARINDEX(' ', @ФИООбр, @ч1 + 1);
    IF @ч2 = 0 RETURN LEFT(@ФИООбр, @ч1) + LEFT(SUBSTRING(@ФИООбр, @ч1 + 1, 50), 1) + '.';
    RETURN LEFT(@ФИООбр, @ч1) + LEFT(SUBSTRING(@ФИООбр, @ч1 + 1, 50), 1) + '. ' + LEFT(SUBSTRING(@ФИООбр, @ч2 + 1, 50), 1) + '.';
END;
GO

CREATE OR ALTER FUNCTION med.fn_ПозицияПоставки_Сумма (@Количество INT, @ЦенаЗакупки DECIMAL(10,2)) RETURNS DECIMAL(12,2) AS
BEGIN
    IF @Количество IS NULL OR @ЦенаЗакупки IS NULL OR @Количество <= 0 OR @ЦенаЗакупки <= 0 RETURN 0;
    RETURN @Количество * @ЦенаЗакупки;
END;
GO

CREATE OR ALTER FUNCTION med.fn_Диагноз_Полное (@КодМКБ10 NVARCHAR(10), @Наименование NVARCHAR(200)) RETURNS NVARCHAR(220) AS
BEGIN
    RETURN @КодМКБ10 + N' — ' + @Наименование;
END;
GO

CREATE OR ALTER FUNCTION med.fn_Запись_СтатусТекст (@Статус NVARCHAR(20)) RETURNS NVARCHAR(20) AS
BEGIN
    IF @Статус IS NULL RETURN N'Неизвестно';
    RETURN CASE @Статус WHEN N'активна' THEN N'Активен' WHEN N'отменена' THEN N'Отменён' WHEN N'завершена' THEN N'Завершён' ELSE N'Неизвестно' END;
END;
GO

CREATE OR ALTER FUNCTION med.fn_Расписание_Интервал (@ВремяНачала TIME, @ВремяОкончания TIME) RETURNS VARCHAR(11) AS
BEGIN
    IF @ВремяНачала IS NULL OR @ВремяОкончания IS NULL RETURN '—';
    RETURN FORMAT(CAST(@ВремяНачала AS DATETIME), 'HH:mm') + '–' + FORMAT(CAST(@ВремяОкончания AS DATETIME), 'HH:mm');
END;
GO

CREATE OR ALTER FUNCTION med.fn_Запись_ПациентаЗаПериод (@ПациентID INT, @ДатаС DATE, @ДатаПо DATE) RETURNS TABLE AS
RETURN (
    SELECT з.ID AS ЗаписьID, з.Дата, з.Время, в.ФИО AS Врач, сп.Наименование AS Специализация, з.Статус, med.fn_Запись_СтатусТекст(з.Статус) AS СтатусТекст
    FROM med.Запись з
    JOIN med.Врач в ON в.ID = з.ВрачID
    JOIN med.Специализация сп ON сп.ID = в.СпециализацияID
    WHERE з.ПациентID = @ПациентID AND з.Дата BETWEEN @ДатаС AND @ДатаПо
);
GO

CREATE OR ALTER FUNCTION med.fn_Расписание_СвободныеИнтервалы (@ВрачID INT, @Дата DATE) RETURNS TABLE AS
RETURN (
    SELECT р.ID AS РасписаниеID, р.ВремяНачала, р.ВремяОкончания, med.fn_Расписание_Интервал(р.ВремяНачала, р.ВремяОкончания) AS Интервал
    FROM med.Расписание р
    WHERE р.ВрачID = @ВрачID AND р.Дата = @Дата AND NOT EXISTS (
        SELECT 1 FROM med.Запись з WHERE з.ВрачID = р.ВрачID AND з.Дата = р.Дата AND з.Время BETWEEN р.ВремяНачала AND р.ВремяОкончания AND з.Статус = N'активна'
    )
);
GO

CREATE OR ALTER FUNCTION med.fn_Диагноз_ПоПациенту (@ПациентID INT) RETURNS TABLE AS
RETURN (
    SELECT з.Дата AS ДатаПриёма, в.ФИО AS Врач, сп.Наименование AS Специализация, д.КодМКБ10, д.Наименование AS Диагноз, med.fn_Диагноз_Полное(д.КодМКБ10, д.Наименование) AS ДиагнозПолное
    FROM med.Запись з
    JOIN med.Медкарта м ON м.ЗаписьID = з.ID
    JOIN med.Диагноз д ON д.МедкартаID = м.ID
    JOIN med.Врач в ON в.ID = з.ВрачID
    JOIN med.Специализация сп ON сп.ID = в.СпециализацияID
    WHERE з.ПациентID = @ПациентID
);
GO

CREATE OR ALTER FUNCTION med.fn_Врач_ЗагрузкаНаДату (@Дата DATE) RETURNS TABLE AS
RETURN (
    SELECT в.ID AS ВрачID, в.ФИО AS Врач, сп.Наименование AS Специализация, COUNT(з.ID) AS ВсегоТалонов, SUM(CASE WHEN з.Статус = N'активна' THEN 1 ELSE 0 END) AS Активных, SUM(CASE WHEN з.Статус = N'отменена' THEN 1 ELSE 0 END) AS Отменённых
    FROM med.Врач в
    JOIN med.Специализация сп ON сп.ID = в.СпециализацияID
    LEFT JOIN med.Запись з ON з.ВрачID = в.ID AND з.Дата = @Дата
    GROUP BY в.ID, в.ФИО, сп.Наименование
);
GO

CREATE OR ALTER FUNCTION med.fn_ОстаткиЛекарств (@ПорогНизкий INT = 10, @ПорогВысокий INT = 100) RETURNS @Результат TABLE (ЛекарствоID INT, Лекарство NVARCHAR(150), ФормаВыпуска NVARCHAR(50), Поступило INT, Израсходовано INT, Остаток INT, Статус NVARCHAR(20)) AS
BEGIN
    INSERT INTO @Результат (ЛекарствоID, Лекарство, ФормаВыпуска, Поступило, Израсходовано, Остаток, Статус)
    SELECT л.ID, л.Наименование, л.ФормаВыпуска, ISNULL(SUM(пп.Количество), 0), 0, 0, N''
    FROM med.Лекарство л LEFT JOIN med.ПозицияПоставки пп ON пп.ЛекарствоID = л.ID
    GROUP BY л.ID, л.Наименование, л.ФормаВыпуска;

    UPDATE @Результат SET Израсходовано = Поступило / 10;
    UPDATE @Результат SET Остаток = Поступило - Израсходовано;
    UPDATE @Результат SET Статус = CASE WHEN Остаток <= 0 THEN N'Нет в наличии' WHEN Остаток < @ПорогНизкий THEN N'Низкий остаток' WHEN Остаток >= @ПорогВысокий THEN N'Достаточно' ELSE N'Средний остаток' END;
    RETURN;
END;
GO

CREATE OR ALTER PROCEDURE proc_Пациент_Добавить (@ФИО NVARCHAR(150), @ДатаРождения DATE, @Пол CHAR(1), @ПолисОМС NVARCHAR(16), @НовыйID INT OUTPUT) AS
BEGIN
    SET NOCOUNT ON;
    IF @ФИО IS NULL OR @ПолисОМС IS NULL THROW 50001, N'Обязательные поля не заполнены', 1;
    IF EXISTS (SELECT 1 FROM med.Пациент WHERE ПолисОМС = @ПолисОМС) THROW 50003, N'Пациент с таким полисом уже существует', 1;
    INSERT INTO med.Пациент (ФИО, ДатаРождения, Пол, ПолисОМС) VALUES (@ФИО, @ДатаРождения, @Пол, @ПолисОМС);
    SET @НовыйID = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE proc_Пациент_НайтиПоПолису (@ПолисОМС NVARCHAR(16)) AS
BEGIN
    SET NOCOUNT ON;
    IF @ПолисОМС IS NULL OR LEN(@ПолисОМС) = 0 THROW 50001, N'Номер полиса обязателен', 1;
    SELECT ID, ФИО, ДатаРождения, Пол, ПолисОМС, СНИЛС, Телефон FROM med.Пациент WHERE ПолисОМС = @ПолисОМС;
END;
GO

CREATE OR ALTER PROCEDURE proc_Пациент_НайтиПоФИО (@ФИО NVARCHAR(150)) AS
BEGIN
    SET NOCOUNT ON;
    IF @ФИО IS NULL OR LEN(@ФИО) = 0 THROW 50001, N'Параметр @ФИО обязателен', 1;
    SELECT ID, ФИО, ДатаРождения, Пол, ПолисОМС, СНИЛС, Телефон FROM med.Пациент WHERE ФИО LIKE @ФИО + '%' ORDER BY ФИО;
END;
GO

CREATE OR ALTER PROCEDURE proc_Расписание_НаДату (@ВрачID INT, @Дата DATE = NULL) AS
BEGIN
    SET NOCOUNT ON;
    IF @ВрачID IS NULL THROW 50001, N'Параметр @ВрачID обязателен', 1;
    IF @Дата IS NULL SET @Дата = CAST(GETDATE() AS DATE);
    SELECT р.ID, в.ФИО AS Врач, р.Дата, р.ВремяНачала, р.ВремяОкончания FROM med.Расписание р JOIN med.Врач в ON в.ID = р.ВрачID WHERE р.ВрачID = @ВрачID AND р.Дата = @Дата ORDER BY р.ВремяНачала;
END;
GO

CREATE OR ALTER PROCEDURE proc_Запись_Создать (@ПациентID INT, @ВрачID INT, @Дата DATE, @Время TIME, @НовыйID INT OUTPUT) AS
BEGIN
    SET NOCOUNT ON;
    IF @ПациентID IS NULL OR @ВрачID IS NULL OR @Дата IS NULL OR @Время IS NULL THROW 50001, N'Обязательные поля не заполнены', 1;
    IF NOT EXISTS (SELECT 1 FROM med.Пациент WHERE ID = @ПациентID) THROW 50004, N'Пациент не найден', 1;
    IF NOT EXISTS (SELECT 1 FROM med.Врач WHERE ID = @ВрачID) THROW 50008, N'Врач не найден', 1;
    IF EXISTS (SELECT 1 FROM med.Запись WHERE ВрачID = @ВрачID AND Дата = @Дата AND Время = @Время AND Статус = N'активна') THROW 50014, N'Интервал уже занят', 1;
    INSERT INTO med.Запись (ПациентID, ВрачID, Дата, Время, Статус) VALUES (@ПациентID, @ВрачID, @Дата, @Время, N'активна');
    SET @НовыйID = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE proc_Запись_Отменить (@ID INT) AS
BEGIN
    SET NOCOUNT ON;
    IF @ID IS NULL THROW 50001, N'ID обязателен', 1;
    IF NOT EXISTS (SELECT 1 FROM med.Запись WHERE ID = @ID) THROW 50015, N'Запись не найдена', 1;
    UPDATE med.Запись SET Статус = N'отменена' WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE proc_Запись_ОформитьСМедкартой (@ПациентID INT, @ВрачID INT, @Дата DATE, @Время TIME, @ЗаписьID INT OUTPUT) AS
BEGIN
    SET NOCOUNT ON;
    SET @ЗаписьID = 0;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM med.Запись WHERE ВрачID = @ВрачID AND Дата = @Дата AND Время = @Время AND Статус = N'активна') THROW 50014, N'Интервал уже занят', 1;
        INSERT INTO med.Запись (ПациентID, ВрачID, Дата, Время, Статус) VALUES (@ПациентID, @ВрачID, @Дата, @Время, N'активна');
        SET @ЗаписьID = SCOPE_IDENTITY();
        INSERT INTO med.Медкарта (ЗаписьID, Жалобы, Заключение) VALUES (@ЗаписьID, NULL, NULL);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        INSERT INTO med.ЖурналОшибок (Процедура, Сообщение, НомерОшибки) VALUES (N'proc_Запись_ОформитьСМедкартой', ERROR_MESSAGE(), ERROR_NUMBER());
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE proc_Отчет_ЗагрузкаВрачаНаДату (@Дата DATE) AS
BEGIN
    SET NOCOUNT ON;
    IF @Дата IS NULL THROW 50001, N'Параметр @Дата обязателен', 1;
    SELECT Врач, Специализация, ВсегоТалонов, Активных, Отменённых FROM med.fn_Врач_ЗагрузкаНаДату(@Дата) ORDER BY ВсегоТалонов DESC;
END;
GO

CREATE OR ALTER PROCEDURE proc_Отчет_РасходыНаЛекарстваЗаПериод (@ДатаС DATE, @ДатаПо DATE) AS
BEGIN
    SET NOCOUNT ON;
    IF @ДатаС IS NULL OR @ДатаПо IS NULL THROW 50001, N'Параметры @ДатаС и @ДатаПо обязательны', 1;
    SELECT л.Наименование AS Лекарство, л.ФормаВыпуска AS Форма, SUM(пп.Количество) AS ВсегоКоличество, AVG(пп.ЦенаЗакупки) AS СредняяЦена, SUM(med.fn_ПозицияПоставки_Сумма(пп.Количество, пп.ЦенаЗакупки)) AS СуммаРасходов
    FROM med.Поставка п
    JOIN med.ПозицияПоставки пп ON пп.ПоставкаID = п.ID
    JOIN med.Лекарство л ON л.ID = пп.ЛекарствоID
    WHERE п.Дата BETWEEN @ДатаС AND @ДатаПо
    GROUP BY л.Наименование, л.ФормаВыпуска
    ORDER BY СуммаРасходов DESC;
END;
GO

CREATE OR ALTER TRIGGER trg_Пациент_Audit ON med.Пациент AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO med.АудитИзменений (Таблица, Операция, КлючЗаписи, Данные)
    SELECT N'Пациент', N'INSERT', i.ID, CONCAT(N'ФИО: ', i.ФИО, N'; Полис: ', i.ПолисОМС) FROM inserted i WHERE i.ID NOT IN (SELECT ID FROM deleted);

    INSERT INTO med.АудитИзменений (Таблица, Операция, КлючЗаписи, Данные)
    SELECT N'Пациент', N'UPDATE', i.ID, CONCAT(N'Старое ФИО: ', d.ФИО, N' -> Новое: ', i.ФИО, N'; Старый тел.: ', ISNULL(d.Телефон, N'—'), N' -> Новый: ', ISNULL(i.Телефон, N'—')) FROM inserted i JOIN deleted d ON d.ID = i.ID;

    INSERT INTO med.АудитИзменений (Таблица, Операция, КлючЗаписи, Данные)
    SELECT N'Пациент', N'DELETE', d.ID, CONCAT(N'ФИО: ', d.ФИО, N'; Полис: ', d.ПолисОМС) FROM deleted d WHERE d.ID NOT IN (SELECT ID FROM inserted);
END;
GO

CREATE OR ALTER TRIGGER trg_Запись_Audit ON med.Запись AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO med.АудитИзменений (Таблица, Операция, КлючЗаписи, Данные)
    SELECT N'Запись', N'INSERT', i.ID, CONCAT(N'ПациентID: ', i.ПациентID, N'; ВрачID: ', i.ВрачID, N'; Дата: ', CONVERT(NVARCHAR(10), i.Дата, 104), N'; Время: ', CONVERT(NVARCHAR(5), i.Время, 108), N'; Статус: ', i.Статус) FROM inserted i WHERE i.ID NOT IN (SELECT ID FROM deleted);

    INSERT INTO med.АудитИзменений (Таблица, Операция, КлючЗаписи, Данные)
    SELECT N'Запись', N'UPDATE', i.ID, CONCAT(N'Старый статус: ', d.Статус, N' -> Новый статус: ', i.Статус) FROM inserted i JOIN deleted d ON d.ID = i.ID;

    INSERT INTO med.АудитИзменений (Таблица, Операция, КлючЗаписи, Данные)
    SELECT N'Запись', N'DELETE', d.ID, CONCAT(N'ПациентID: ', d.ПациентID, N'; ВрачID: ', d.ВрачID, N'; Дата: ', CONVERT(NVARCHAR(10), d.Дата, 104), N'; Статус: ', d.Статус) FROM deleted d WHERE d.ID NOT IN (SELECT ID FROM inserted);
END;
GO

CREATE OR ALTER TRIGGER trg_Запись_ПроверкаИнтервала ON med.Запись AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i JOIN med.Запись z ON z.ВрачID = i.ВрачID AND z.Дата = i.Дата AND z.Время = i.Время AND z.Статус = N'активна' AND z.ID <> i.ID WHERE i.Статус = N'активна')
        THROW 50014, N'На этот интервал у врача уже есть активная запись', 1;

    IF EXISTS (SELECT 1 FROM inserted i WHERE NOT EXISTS (SELECT 1 FROM med.Расписание r WHERE r.ВрачID = i.ВрачID AND r.Дата = i.Дата AND i.Время >= r.ВремяНачала AND i.Время < r.ВремяОкончания))
        THROW 50030, N'Время отсутствует в расписании врача', 1;

    IF EXISTS (SELECT 1 FROM inserted i WHERE NOT EXISTS (SELECT 1 FROM med.Пациент p WHERE p.ID = i.ПациентID))
        THROW 50004, N'Указан несуществующий пациент', 1;
END;
GO

CREATE OR ALTER TRIGGER trg_Специализация_InsteadOfDelete ON med.Специализация INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted d JOIN med.Врач v ON v.СпециализацияID = d.ID JOIN med.Запись z ON z.ВрачID = v.ID AND z.Статус = N'активна')
        THROW 50040, N'Нельзя архивировать специализацию: есть активные записи у врачей', 1;

    UPDATE s SET Активна = 0 FROM med.Специализация s JOIN deleted d ON d.ID = s.ID;
END;
GO

CREATE OR ALTER TRIGGER trg_Врач_InsteadOfDelete ON med.Врач INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted d JOIN med.Запись z ON z.ВрачID = d.ID AND z.Статус = N'активна')
        THROW 50009, N'Нельзя удалить врача с активными записями', 1;

    DELETE v FROM med.Врач v JOIN deleted d ON d.ID = v.ID;
END;
GO