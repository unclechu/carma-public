{
    "title": "Кейс",
    "canCreate": true,
    "canRead": true,
    "canUpdate": true,
    "canDelete": true,
    "fields": [
        {
            "name": "callDate",
            "label": "Дата звонка",
            "canWrite": true,
            "canRead": true,
            "index": true
        },
        {
            "name": "callTime",
            "label": "Время звонка",
            "canWrite": true,
            "canRead": true
        },
        {
            "name": "callTaker",
            "label": "Сотрудник РАМК",
            "canWrite": false,
            "canRead": true,
            "required": true
        },
        {
            "name": "program",
            "label": "Программа",
            "canWrite": true,
            "canRead": true,
            "required": true,
            "index": true
        },
        {
            "name": "callerName",
            "label": "ФИО звонящего",
            "canWrite": true,
            "canRead": true
        },
        {
            "name": "ownerName",
            "label": "ФИО владельца",
            "canWrite": true,
            "canRead": true
        },
        {
            "name": "service",
            "label": "Услуга",
            "type": "reference",
            "referencables": ["tech", "towage", "hotel"],
            "canWrite": true,
            "canRead": true,
            "required": true,
            "index": true
        },
        {
            "name": "phone",
            "label": "Мобильный телефон",
            "canWrite": true,
            "canRead": true,
            "index": true
        },
        {
            "name": "extraPhone",
            "label": "Дополнительный телефон",
            "canWrite": true,
            "canRead": true
        },
        {
            "name": "manufacturer",
            "label": "Марка автомобиля",
            "canWrite": true,
            "canRead": true
        },
        {
            "name": "model",
            "label": "Модель автомобиля",
            "canWrite": true,
            "canRead": true
        },
        {
            "name": "othermodel",
            "label": "Другая марка / модель авто",
            "canWrite": true,
            "canRead": true
        },
        {
            "name": "plateNum",
            "label": "Регистрационный номер автомобиля",
            "canWrite": true,
            "canRead": true,
            "index": true
        },
        {
            "name": "color",
            "label": "Цвет",
            "canWrite": true,
            "canRead": true
        },
        {
            "name": "vin",
            "label": "VIN автомобиля",
            "canWrite": true,
            "canRead": true
        },
        {
            "name": "vinCheck",
            "label": "VIN Проверен",
            "canWrite": true,
            "canRead": true,
            "type": "checkbox"
        },
        {
            "name": "purchased",
            "label": "Дата покупки автомобиля",
            "canWrite": true,
            "canRead": true
        },
        {
            "name": "caseAddress",
            "label": "Адрес места поломки",
            "canWrite": true,
            "canRead": true
        },
        {
            "name": "comment",
            "label": "Комментарий",
            "type": "textarea",
            "canWrite": true,
            "canRead": true
        },
        {
            "name": "status",
            "label": "Статус звонка",
            "canWrite": true,
            "canRead": true,
            "required": true
        }
    ]
}
