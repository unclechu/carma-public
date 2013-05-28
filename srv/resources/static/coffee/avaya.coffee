class Phone
  constructor: (ext,pwd) ->
    url = "ws://#{location.hostname}:8001/avaya/#{ext}/#{pwd}"
    @ws = new WebSocket(url)
    @ws.onopen = => @connected()
    @ws.onclose = => @destructor()
    @ws.onerror = => @destructor()

    @ws.onmessage = (ev) =>
      msg = JSON.parse(ev.data)
      if msg.type == "ringer"
        if msg.ringer == "ringing"
          @calling()
        else
          @notCalling()
      else if msg.type == "display"
        m = msg.display.match(/a=\s*(\d+)\s*to\s*(.*\S)\s*/)
        if m
          number = m[1].replace(/^(98|8|)(\d{10})$/, '\+7$2')
          @callInfo(number, m[2])

  acceptCall: ->
    @ws.send('acceptCall')

  call: (number) ->
    @ws.send("dial:" + number.replace(/^\+7/,'98'))


class @AvayaWidget
  constructor: (panel, ext, pwd) ->
    phone = new Phone(ext, pwd)
    @__phone = phone # test hook
    phone.connected = ->
      panel.show()
      panel.find('#avaya-accept').click (e)->
        e.preventDefault()
        phone.acceptCall()
      panel.find('#avaya-call').click ->
        number = panel.find(".search-query").val()
        phone.call(number)

    phone.destructor = ->
      panel.hide()

    phone.calling = ->
      panel.addClass("open")

    phone.notCalling = ->
      panel.removeClass("open")

    phone.callInfo = (number, line) ->
      phone.calling()
      panel.find(".search-query")
        .val(number)
        .css("background", if number in redNumbers then "coral" else "white")

      $("#search-query").val("!Тел:" + number)
      $("#search-query").change()

      vm = global.viewsWare['call-form'].knockVM
      vm.callerName_phone1(number)
      info = lineInfo[line]
      if info
        panel.find("#avaya-info").text(info.greeting)
        vm.programLocal(info.program)

  call: (number) ->
    @__phone.call(number)


redNumbers =
  [ "+79851996802"
  , "+79151747332"
  , "+79067510641"
  , "+79623619523"
  , "+79267474413"
  , "+79162169927"
  , "+79168454204"
  , "+79264304598"
  , "+79851996802"
  , "+79851996809"
  ]

lineInfo =
  "VW+BOSCH":
    greeting: "VW Гарантия мобильности, имя оператора, чем могу Вам помочь?"
    program: "VW / Легковые автомобили"
  "GM KOREA":
    greeting: "GM ассистанс, добрый день, чем могу Вам помочь?"
    program: "GM / Chevrolet Korea"
  "GM+BOSCH":
    greeting: "GM ассистанс, добрый день, чем могу Вам помочь?"
    program: "GM / Opel (после 01.04.2011)"
  "FORD+BOSCH":
    greeting: "Ford помощь на дорогах, имя оператора, добрый день, чем могу Вам помочь?"
    program: "Ford"
  "ARC CLUBS":
    greeting: "Русский АвтоМотоКлуб, имя оператора, добрый день! (Здравствуйте!)"
    program: "B2B / Arc B2B"
  "RAMC B2C":
    greeting: "Русский АвтоМотоКлуб, имя оператора, добрый день! (Здравствуйте!)"
    program: "B2C карты / Стандарт"
  "RUS-LAN":
    greeting: "Рус-Лан ассистанс, имя оператора, добрый день, чем могу Вам помочь?"
    program: "Рус Лан"
  "ATLANT-M":
    greeting: "Атлант М Ассистанс, имя оператора, добрый день, чем могу Вам помочь?"
    program: "Атлант М"
  "CHARTIS":
    greeting: "Надёжный патруль Чартис, имя оператора, добрый день, чем могу Вам помочь?"
    program: "Chartis Assistance"
  "VW AVILON":
    greeting: "Авилон ассистанс, имя оператора, добрый день, чем могу Вам помочь?"
    program: "B2B / Авилон"
  "NEZAVISIMOST":
    greeting: "Независимость Ассистанс, имя оператора, добрый день, чем могу Вам помочь?"
    program: "Независимость"
  "EUROPLAN":
    greeting: "Европлан Ассистанс, имя оператора, добрый день, чем могу Вам помочь?"
    program: "B2B / Европлан"
  "MAPFRE":
    greeting: "Ассистанс центр МАПФРЕ УОРРЭНТИ, добрый день, чем могу Вам помочь?"
    program: "B2B / Мапфре"
  "FWC VNUKOVO":
    greeting: "Фольксваген Внуково Ассистанс, имя оператора, добрый день, чем могу Вам помочь?"
    program: "B2B / VW Внуково"
  "RN CART":
    greeting: "Москва Помощь на Дорогах, имя оператора, добрый день, чем могу Вам помочь?"
    program: "B2B / РН-карт-Москва Базовая"
  "UNICREDITBANK":
    greeting: "Русский АвтоМотоКлуб, имя оператора, добрый день! (Здравствуйте!)"
    program: "B2C / ЮниКредитбанк"
  "VTB 24":
    greeting: "Русский АвтоМотоКлуб, имя оператора, добрый день! (Здравствуйте!)"
    program: "B2C / ВТБ 24"
  "RAMC":
    greeting: "Русский АвтоМотоКлуб, имя оператора, добрый день! (Здравствуйте!)"
    program: ""
  "RAMC 2":
    greeting: "Русский АвтоМотоКлуб, имя оператора, добрый день! (Здравствуйте!)"
    program: ""
