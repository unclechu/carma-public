<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>CaRMa</title>
    <link rel="stylesheet" href="/s/css/bootstrap.min.css" />
    <link rel="stylesheet" href="/s/css/datepicker.css" />
    <link rel="stylesheet" href="/s/css/jquery.dataTables.css" />

    <!-- Additional set of icons -->
    <link rel="stylesheet" href="/s/css/stolen-icons.css" />

    <link rel="stylesheet" href="/s/css/local.css" />

    <!-- DOM manipulation -->
    <script src="/s/js/3p/jquery-1.7.1.min.js" />

    <!-- Rich UI -->
    <script src="/s/js/3p/bootstrap.min.js" />
    <script src="/s/js/3p/bootstrap-datepicker.js" />
    <script src="/s/js/3p/bootstrap-typeahead.js" />
    <script src="/s/js/3p/bootstrap-popover.js" />

    <!-- Tabular display -->
    <script src="/s/js/3p/jquery.dataTables.min.js" />

    <!-- Responsive UI javascript library -->
    <script src="/s/js/3p/knockout-2.0.0.js" />

    <!-- Utility library, Backbone dependency -->
    <script src="/s/js/3p/underscore-1.3.1.min.js" />

    <!-- Loose MVC -->
    <script src="/s/js/3p/backbone-0.9.1.min.js" />

    <!-- Knockback is a Knockout + Backbone glue -->
    <script src="/s/js/3p/knockback-0.13.min.js" />

    <!-- Simple templates -->
    <script src="/s/js/3p/mustache.js" />

    <!-- OpenLayers library allows map rendering -->
    <script src="http://www.openlayers.org/api/OpenLayers.js" />

    <!-- 25Kb of date parsing and formatting -->
    <script src="/s/js/3p/date-ru-RU.js" />

    <!-- masked input for datetime fields -->
    <script src="/s/js/3p/jquery.maskedinput-1.3.js" />

    <script src="/s/js/customKoHandlers.js" />

    <!-- Model processing -->
    <script src="/s/js/metamodel.js" />
    <script src="/s/js/search.js" />
    <script src="/s/js/main.js" />
    <script src="/s/js/local.js" />
    <script src="/s/js/viewsware.js" />
  </head>
  <body>
    <!-- Navigation bar on top -->
    <div class="navbar navbar-fixed-top">
      <div class="navbar-inner">
        <div class="container">
          <ul class="nav">
            <a class="brand" href="/">
              CaRMa
            </a>
            <li class="divider-vertical" />
            <li id="call-screen-nav">
              <a href="#call">Звонок</a>
            </li>
            <li id="case-screen-nav">
              <a href="#case">Кейс</a>
            </li>
            <li id="back-screen-nav">
              <a href="#back">Бэкофис</a>
            </li>
            <li id="search-screen-nav">
              <a href="#search">Поиск</a>
            </li>
            <li class="dropdown">
              <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                Ещё <b class="caret"></b>
              </a>
              <ul class="dropdown-menu">
                <li id="vin-screen-nav">
                  <a href="#vin">Обновление базы VIN</a>
                </li>
                <li id="partner-screen-nav">
                  <a href="#partner">Редактирование партнёров</a>
                </li>
                <li id="reports-screen-nav">
                  <a href="#reports">Отчёты</a>
                </li>
              </ul>
            </li>
          </ul>
          <ifLoggedIn>
            <ul class="nav pull-right">
              <li class="divider-vertical" />
              <li class="dropdown">
                <a href="#"
                   class="dropdown-toggle"
                   data-toggle="dropdown">
                  <i class="icon-user icon-white" />&nbsp;<loggedInUser />
                  <b class="caret"></b>
                </a>
                <ul class="dropdown-menu">
                  <li>
                    <a href="/logout/">
                      <i class="icon-off icon-black" />&nbsp;Выход
                    </a>
                </ul>
              </li>
            </ul>
          </ifLoggedIn>
        </div>
      </div>
    </div>

    <!-- Main container for dynamically rendered layouts -->
    <div class="container-fluid">
      <div class="row-fluid" id="layout" />
    </div>

    <!-- Call handling screen layout -->
    <script type="text/template"
            class="screen-template"
            id="call-screen-template">
      <div id="left" class="nice-scrollbar call-pane">
        <div id="call-form"/>
        <button class="btn btn-success"
                type="submit"
                onClick="makeCase()" >
          Новый кейс
        </button>
      </div>
      <div id="center" class="nice-scrollbar call-pane"/>
      <div id="bottom">
        <table id="call-searchtable" class="table table-striped table-bordered">
          <thead>
            <tr>
              <th>ID</th>
              <th>ФИО</th>
              <th>Дата звонка</th>
              <th>Телефон</th>
              <th>Номер машины</th>
              <th>VIN</th>
              <th>Программа</th>
              <th>Комментарий</th>
            </tr>
          </thead>
          <tbody/>
        </table>
      </div>
    </script>

    <!-- Case screen layout -->
    <script type="text/template"
            class="screen-template"
            id="case-screen-template">
      <!-- Main case form -->
      <div id="left"
           class="nice-scrollbar pane"
           onKeydown="handleLeftHotkey(event)">
        <form class="form-vertical">
          <div class="control-group">
            <div class="control-label">
              <label>Номер</label>
            </div>
            <div class="controls">
              <input type="text" disabled id="case-number"
                     data-bind="value: maybeId"/>
            </div>
          </div>
          <div id="case-form" />
          
          <div class="control-group">
            <div class="control-label">
              <label>Услуги</label>
            </div>
            <div class="controls">
              <span class="accordion" id="case-services-references" />
              
              <span id="service-picker-container" />
            </div>
          </div>
          
          <div id="case-permissions" />
        </div>
      </div>

      <!-- Central pane with subform -->
      <!--
      TODO Should be spanN when fluid containers are fixed in
           Bootstrap upstream. -->
      <div id="center"
           class="nice-scrollbar pane"
           onKeydown="handleCenterHotkey(event)">
      </div>

      <!-- Rightmost pane with list of empty fields and action notes
      -->
      <div id="right" class="nice-scrollbar pane">
        <form class="form-vertical">
          <div class="control-group">
            <div class="controls">
              <span class="accordion" id="case-actions-references" />
            </div>
          </div>
        </form>
        <div id="empty-fields-placeholder" />
      </div>
    </script>

    <!-- Search screen -->
    <script type="text/template"
            id="search-screen-template"
            class="screen-template">
      <!-- Can't use offsetN class here due to fluid layout. -->
      <div id="tableView" />
    </script>

    <script type="text/template"
            id="search-table-template"
            class="view-template">
      <div style="text-align:center;">
      <fieldset style="width:50%; margin-left:25%;">
        <legend>Поиск</legend>
        <form onsubmit="gotoCase(); return false;">
          <div data-date-format="dd.mm.yyyy" 
               id="search-datepicker"
               data-provide="datepicker"
               data-date-weekstart="1"
               class="input-append date">
	    <input type="text"
                   style="width: 90%;"
                   id="table-query"
                   size="16" class="span2" id="acpro_inp2">
	    <span class="add-on"><i class="icon-calendar"></i></span>
          </div>
          <button class="btn btn-success" type="submit">
            Поиск
          </button>
        </form>
      </fieldset>
      </div>
      <table id="searchtable" class="table table-striped table-bordered">
        <thead>
          <tr>
            <th>ID</th>
            <th>ФИО</th>
            <th>Дата звонка</th>
            <th>Телефон</th>
            <th>Номер машины</th>
            <th>Программа</th>
          </tr>
        </thead>
        <tbody/>
      </table>
    </script>

    <!-- Backoffice screen -->
    <script type="text/template"
            id="back-screen-template"
            class="screen-template">
      <center>
        <table width="80%">
          <thead>
            <tr><th>Мои задачи</th><th>Общие задачи</th></tr>
          </thead>
          <tr><td width="50%">
            <table id="back-user-table" class="table table-striped table-bordered">
              <thead>
                <tr>
                  <th>Кейс</th>
                  <th>Приоритет</th>
                  <th>Дата выполнения</th>
                  <th>Что делать?</th>
                  <th>Комментарии</th>
                </tr>
              </thead>
              <tbody/>
            </table>
          </td>
          <td width="50%">
            <table id="back-group-table" class="table table-striped table-bordered">
              <thead>
                <tr>
                  <th>Кейс</th>
                  <th>Приоритет</th>
                  <th>Дата выполнения</th>
                  <th>Что делать?</th>
                  <th>Комментарии</th>
                </tr>
              </thead>
              <tbody/>
            </table>
          </td></tr>
        </table>
      </center>
    </script>

    <!-- reports generation screen -->
    <script type="text/template"
            id="reports-screen-template"
            class="screen-template">
      <div style="width:30%;margin:0 auto;text-align:center;">
      <fieldset>
        <legend>Отчёты</legend>
        <form action="/report">
          <p>
            <div class="input-append date"
                 data-provide="datepicker"
                 data-autoshow-datepicker="true"
                 data-date-format="dd.mm.yyyy"
                 data-date-weekstart="1">
              <input type="text" class="pane-span focusable" name="from"/>
              <span class="add-on"><i class="icon icon-calendar" /></span>
            </div>
            <div class="input-append date"
                 data-provide="datepicker"
                 data-autoshow-datepicker="true"
                 data-date-format="dd.mm.yyyy"
                 data-date-weekstart="1">
              <input type="text" class="pane-span focusable" name="to"/>
              <span class="add-on"><i class="icon icon-calendar" /></span>
            </div>
            <select name="program">
              <option value="all">Все программы</option>
              <option value="ford">Ford</option>
              <option value="fordPlus">Ford+</option>
              <option value="vwMotor">VW Легковые</option>
              <option value="vwCommercial">VW Коммерческие</option>
              <option value="opel">Opel</option>
              <option value="hummer">Hummer</option>
              <option value="chevroletNAO">Chevrolet NAO</option>
              <option value="chevroletKorea">Chevrolet Korea</option>
              <option value="cadillac">Cadillac</option>
              <option value="vwRuslan">VW Рус-Лан</option>
              <option value="chartis">Chartis</option>
              <option value="vwAvilon">VW Avilon</option>
              <option value="atlantM">Атлант-М</option>
              <option value="autocraft">AutoCraft</option>
              <option value="b2c">B2C</option>
            </select>
          </p>
          <button class="btn btn-success" type="submit">Отчёт</button>
        </form>
      </fieldset>
      </div>
    </script>

    <!-- Import VINs screen -->
    <script type="text/template"
            id="vin-screen-template"
            class="screen-template">
      <div id="vin-form" />
    </script>

    <script type="text/template"
            id="vin-form-template"
            class="view-template">
      <div style="text-align:center;">
      <fieldset>
        <legend>Импорт VIN</legend>
        <form id="vin-import-form" onsubmit="doVin(); return false;">
          <p>
            <select name="program">
              <option value="ford">Ford</option>
              <option value="fordPlus">Ford+</option>
              <option value="vwMotor">VW Легковые</option>
              <option value="vwCommercial">VW Коммерческие</option>
              <option value="opel">Opel</option>
              <option value="hummer">Hummer</option>
              <option value="chevroletNAO">Chevrolet NAO</option>
              <option value="chevroletKorea">Chevrolet Korea</option>
              <option value="cadillac">Cadillac</option>
              <option value="vwRuslan">VW Рус-Лан</option>
              <option value="chartis">Chartis</option>
              <option value="vwAvilon">VW Avilon</option>
              <option value="atlantM">Атлант-М</option>
              <option value="autocraft">AutoCraft</option>
              <option value="b2c">B2C</option>
            </select>
            <input type="file"
                   name="file"
                   accept="text/csv|application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" />
          </p>
          <button class="btn btn-success" type="submit">
            Отправить
          </button>
        </form>
      </fieldset>
      </div>
      <div id="vin-alert-container" />
    </script>

    <script type="text/template"
            id="vin-alert-template">
      <!-- TODO Should be row-fluid when fluid containers are
                fixed in Bootstrap upstream. -->
      <div class="container">
        <div class="row">
          <div class="span6 offset3">
            {{# alerts}}
              <div class="alert alert-{{alertType}}" style="margin-bottom: 2px;">
                <button class="close"
			data-dismiss="alert"
			onclick="removeVinAlert('{{alertId}}'); return false;">×</button>
                {{alertVinFile}}: {{ alertMessage }}
                {{# alertErrorFile }}
                  <a href="{{alertErrorFile}}">Файл</a> с необработанными записями.
                {{/ alertErrorFile }}
                {{# alertErrorLogFile }}
                  <a href="{{alertErrorLogFile}}">Файл</a> с описанием ошибок.
                {{/ alertErrorLogFile }}
              </div>
            {{/ alerts}}
          </div>
        </div>
      </div>
    </script>

    <!-- Partner screen template -->
    <script type="text/template"
            class="screen-template"
            id="partner-screen-template">

      <div id="partner-left" class="nice-scrollbar pane">
        <form class="form-vertical">
          <button class="btn btn-action" type="button"
            onclick="location.hash='partner';location.reload(true);">
            <i class="icon icon-plus"></i>Добавить партнёра
          </button>
          <br/><br/>
          <table id="partner-table" class="table table-striped table-bordered">
            <thead>
              <tr>
                <th>#</th>
                <th>Название</th>
                <th>Город</th>
                <th>Комментарии</th>
              </tr>
            </thead>
            <tbody/>
          </table>
        </form>
      </div>

      <div id="partner-center" class="nice-scrollbar pane">
        <form class="form-vertical">
          <div id="partner-form" />
          <div class="control-group">
            <div class="control-label">
              <label>Услуги</label>
            </div>
            <div class="controls">
              <span class="accordion" id="partner-service-references" />
              <span id="partner-service-picker-container" />
              <button class="dropdown-toggle btn btn-action"
                      onclick="addNewServiceToPartner();"
                      type="button"
                      data-toggle="dropdown">
                <i class="icon icon-plus"></i>Добавить услугу
              </button>
            </div>
          </div>
          <div id="partner-permissions" />
        </form>
      </div>
    </script>

    <!--
         Form field templates.

         Field template must have id in form of <type>-field-template,
         where <type> is field type to be rendered using this
         template, or <name>-<type>-field-template, where <name> is
         the name of field of given type which will be rendered with
         this template. Client code must prefer named templates to
         only-typed ones.

      -->

    <script type="text/template"
            class="field-template"
            id="textarea-field-template">
      <div class="control-group"
           {{# meta.required }}data-bind="css: { error: {{name}}Not }"{{/ meta.required}}
           {{# meta.regexp }}data-bind="css: { warning: {{name}}Regexp }"{{/ meta.regexp}}
           >
        <div class="control-label">
          <label>{{ meta.label }}
            {{# meta.infoText1 }}
              <i class="icon icon-question-sign"
                 data-provide="popover"
                 data-content="{{ meta.infoText1 }}" />
            {{/ meta.infoText1 }}
          </label>
        </div>
        <div class="controls">             
          <textarea class="pane-span focusable"
                    name="{{ name }}"
                    {{# readonly }}disabled{{/ readonly }}
                    rows="7"
                    data-bind="value: {{ name }},
                               valueUpdate: 'afterkeydown'" />
        </div>
      </div>
    </script>

    <script type="text/template"
            class="field-template"
            id="statictext-field-template">
      <div class="control-group">
          <span data-bind="text: {{ name }}" />
      </div>
    </script>

    <script type="text/template"
            class="field-template"
            id="text-field-template">
      <div class="control-group"
           {{# meta.required }}data-bind="css: { error: {{name}}Not }"{{/ meta.required}}
           {{# meta.regexp }}data-bind="css: { warning: {{name}}Regexp }"{{/ meta.regexp}}
           >
        <div class="control-label">
          <label>{{ meta.label }}
            {{# meta.infoText1 }}
              <i class="icon icon-question-sign"
                 data-provide="popover"
                 data-content="{{ meta.infoText1 }}" />
            {{/ meta.infoText1 }}
          </label>
        </div>
        <div class="controls">
          <input type="text"
                 class="pane-span focusable"
                 autocomplete="off"
                 name="{{ name }}"
                 {{# meta.transform }}
                    style="text-transform:{{meta.transform}};"
                 {{/ meta.transform }}
                 {{# readonly }}readonly{{/ readonly }}
                 data-bind="value: {{ name }},
                            valueUpdate: 'afterkeydown'" />
        </div>
      </div>
    </script>

    <script type="text/template"
            class="field-template"
            id="datetime-field-template">
      <div class="control-group"
           {{# meta.required }}data-bind="css: { error: {{name}}Not }"{{/ meta.required}}
           {{# meta.regexp }}data-bind="css: { warning: {{name}}Regexp }"{{/ meta.regexp}}
           >
        <div class="control-label">
          <label>{{ meta.label }}
            {{# meta.infoText1 }}
              <i class="icon icon-question-sign"
                 data-provide="popover"
                 data-content="{{ meta.infoText1 }}" />
            {{/ meta.infoText1 }}
          </label>
        </div>
        <div class="controls">
          <input type="text"
                 class="datetime-field pane-span focusable"
                 autocomplete="off"
                 name="{{ name }}"
                 onFocus="datetimeFieldHandler(this)"
                 {{# readonly }}readonly{{/ readonly }}
                 data-bind="value: {{ name }},
                            valueUpdate: 'afterkeydown'" />
        </div>
      </div>
    </script>

    <!-- Like text-field-template, but with datepicker -->
    <script type="text/template"
            class="field-template"
            id="date-field-template">
      <div class="control-group"
           {{# meta.required }}data-bind="css: { error: {{name}}Not }"{{/ meta.required}}
           {{# meta.regexp }}data-bind="css: { warning: {{name}}Regexp }"{{/ meta.regexp}}
           >
        <div class="control-label">
          <label>{{ meta.label }}
            {{# meta.infoText1 }}
              <i class="icon icon-question-sign"
                 data-provide="popover"
                 data-content="{{ meta.infoText1 }}" />
            {{/ meta.infoText1 }}
          </label>
        </div>
        <div class="controls">
          <div class="input-append date"
               data-provide="datepicker"
               data-autoshow-datepicker="true"
               data-date-format="dd.mm.yyyy"
               data-date-weekstart="1">
            <input type="text"
                   class="pane-span focusable"
                   autocomplete="off"
                   name="{{ name }}"
                   onFocus="onFocusDate(this)"
                   {{# readonly }}readonly{{/ readonly }}
                   data-bind="value: {{ name }},
                              valueUpdate: 'afterkeydown'" />
            <span class="add-on"><i class="icon icon-calendar" /></span>
          </div>
        </div>
      </div>
    </script>

    <!-- Like text-field-template but with call button -->
    <!-- FIXME: this template differs from the picker-field-template
         only in icon class. Seems that it is reasonable to parametrize it.
    -->
    <script type="text/template"
            class="field-template"
            id="phone-field-template">
      <div class="control-group"
           {{# meta.required }}data-bind="css: { error: {{name}}Not }"{{/ meta.required}}
           {{# meta.regexp }}data-bind="css: { warning: {{name}}Regexp }"{{/ meta.regexp}}
           >
        <div class="control-label">
          <label>{{ meta.label }}</label>
        </div>
        <div class="controls">
          <div class="input-append">
            <input type="text"
                   class="pane-span focusable"
                   autocomplete="off"
                   name="{{ name }}"
                   data-bind="value: {{ name }},
                              valueUpdate: 'afterkeydown'"/>
            <span class="add-on">
              <i class="icon stolen-icon-phone"
                 onclick="doPick('{{ meta.picker }}', '{{ name }}');"/>
            </span>
          </div>
        </div>
      </div>
    </script>


    <script type="text/template"
            class="field-template"
            id="dictionary-field-template">
      <div class="control-group"
           {{# meta.required }}data-bind="css: { error: {{name}}Not }"{{/ meta.required}}
           {{# meta.regexp }}data-bind="css: { warning: {{name}}Regexp }"{{/ meta.regexp}}
           >
        <div class="control-label">
          <label>{{ meta.label }}
            {{# meta.infoText1 }}
              <i class="icon icon-question-sign"
                 data-provide="popover"
                 data-content="{{ meta.infoText1 }}" />
            {{/ meta.infoText1 }}
          </label>
        </div>
        <div class="controls">
          <div class="input-append">
            <!-- 

            Note the difference between readonly attribute and
            disabled class from Bootstrap.

            -->
            
            <input type="text"
                   class="pane-span
                          focusable
                          {{# meta.addClass }}{{meta.addClass}}{{/ meta.addClass }}
                          {{# readonly }}disabled{{/ readonly }}"
                   {{# readonly }}readonly{{/ readonly }}
                   autocomplete="off"
                   name="{{ name }}"
                   data-source="global.dictionaries['{{meta.dictionaryName}}']"
                   data-bind="value: {{ name }}Local,
                              valueUpdate: 'afterkeydown'
                              {{# meta.dictionaryParent }},
                              attr: { 'data-parent': {{ meta.dictionaryParent }} }
                              {{/ meta.dictionaryParent }}"
                   data-provide="typeahead" />
            <span class="add-on">
              <i class="icon icon-chevron-down"
                {{^readonly}}data-provide="typeahead-toggle"{{/readonly}}
              />
            </span>
          </div>
          {{# meta.targetCategory }}
          <ul data-depends="{{ name }}"
              data-source="{{ meta.targetCategory }}"
              data-provide="checklist" />
          {{/ meta.targetCategory }}
        </div>
      </div>
    </script>

    <!-- Picker which fills fields with stored data -->
    <script type="text/template"
            class="field-template"
            id="picker-field-template">
      <div class="control-group"
           {{# meta.required }}data-bind="css: { error: {{name}}Not }"{{/ meta.required}}
           {{# meta.regexp }}data-bind="css: { warning: {{name}}Regexp }"{{/ meta.regexp}}
           >
        <div class="control-label">
          <label>{{ meta.label }}
            {{# meta.infoText1 }}
              <i class="icon icon-question-sign"
                 data-provide="popover"
                 data-content="{{ meta.infoText1 }}" />
            {{/ meta.infoText1 }}
          </label>
        </div>
        <div class="controls">
          <div class="input-append">
            <input type="text"
                   class="pane-span focusable {{# readonly }}disabled{{/ readonly }}"
                   autocomplete="off"
                   {{# readonly }}readonly{{/ readonly }}
                   {{# meta.transform }}
                      style="text-transform:{{meta.transform}};"
                   {{/ meta.transform }}
                   name="{{ name }}"
                   data-bind="value: {{ name }},
                              valueUpdate: 'afterkeydown'"/>
            <span class="add-on"><i class="icon icon-search"
               onclick="doPick('{{ meta.picker }}', '{{ name }}', event.srcElement);"/>
            </span>
          </div>
        </div>
      </div>
    </script>

    <!-- radio widget for flat dictionary fields -->
    <script type="text/template"
            class="field-template"
            id="radio-dictionary-field-template">
      <div class="control-group">
        <div class="control-label">
          <label>{{ meta.label }}
            {{# meta.infoText1 }}
              <i class="icon icon-question-sign"
                 data-provide="popover"
                 data-content="{{ meta.infoText1 }}" />
            {{/ meta.infoText1 }}
          </label>
        </div>
        <div class="controls">
          {{# dictionary.entries }}
            <label class="radio">
              <!-- Mustache.js contexts support bubbling -->
              <input type="radio"
                     name="{{ name }}"
                     value="{{ value }}"
                     data-bind="checked: {{ name }}"></input>
              {{ label }}
            </label>
          {{/ dictionary.entries }}
        </div>
      </div>
    </script>

    <!-- May be used for plain rendering of flat dictionaries as well -->
    <script type="text/template"
            class="field-template"
            id="select-field-template">
      <div class="control-group">
        <div class="control-label">
          <label>{{ meta.label }}
            {{# meta.infoText1 }}
              <i class="icon icon-question-sign"
                 data-provide="popover"
                 data-content="{{ meta.infoText1 }}" />
            {{/ meta.infoText1 }}
          </label>
        </div>
        <div class="controls">
          <select name="{{ name }}"
                  {{# readonly }}disabled{{/ readonly }}
                  data-bind="value: {{ name }},
                             valueUpdate: 'change'">
            {{# dictionary.entries }}
            <option value="{{value}}">{{meta.label}}</option>
            {{/ dictionary.entries }}
          </select>
        </div>
      </div>
    </script>

    <script type="text/template"
            class="field-template"
            id="checkbox-field-template">
      <div class="control-group">
        <div class="controls">
          <label class="checkbox inline">
            <input type="checkbox"
                   name="{{ name }}"
                   {{# readonly }}disabled{{/ readonly }}
                   data-bind="checked: {{ name }},
                              valueUpdate: 'change'" />
          {{ meta.label }}
          {{# meta.infoText1 }}
            <i class="icon icon-question-sign"
               data-provide="popover"
               data-content="{{ meta.infoText1 }}" />
          {{/ meta.infoText1 }}
          </label>
        </div>
      </div>
    </script>

    <script type="text/template"
            class="field-template"
            id="map-field-template">
      <div class="control-group">
        <div class="controls">
          <div style="height:600px;" id="{{ name }}" class="osMap"></div>
        </div>
      </div>
    </script>
 
    <script type="text/template"
            class="field-template"
            id="table-field-template">
      <div class="control-group">
        <div class="controls">
          <table id="{{ name }}" class="dataTable table table-striped table-bordered">
            <thead>
              <tr>
                {{# meta.columns }}<th>{{ label }}</th>{{/ meta.columns }}
              </tr>
            </thead>
            <tbody/>
          </table>
        </div>
      </div>
    </script>

    <!-- NOP here — references are rendered after model has loaded -->
    <script type="text/template" 
            class="field-template"
            id="reference-field-template" />

    <!-- 

         Special template used to render first field of group in
         parent view.
    -->
    <script type="text/template" 
            class="field-template"
            id="group-field-template">
      <div class="control-group">
        <div class="control-label">
          <label>{{ meta.label }}
            {{# meta.infoText1 }}
              <i class="icon icon-question-sign"
                 data-provide="popover"
                 data-content="{{ meta.infoText1 }}" />
            {{/ meta.infoText1 }}
          </label>
        </div>
        <div class="controls">
          <div class="input-append">
            <input type="text"
                   class="pane-span"
                   autocomplete="off"
                   {{# meta.transform }}
                      style="text-transform:{{meta.transform}};"
                   {{/ meta.transform }}
                   onfocus="showComplex('{{ viewName }}', '{{ name }}');"
                   {{# readonly }}readonly{{/ readonly }}
                   data-bind="value: {{ name }},
                              valueUpdate: 'afterkeydown'" />
            <span class="add-on">
              <i onclick="showComplex('{{ viewName }}', '{{ name }}');"
                 class="icon icon-share" />
            </span>
          </div>
        </div>
      </div>
    </script>

    <!-- 
    
         Template for one of references.
    
         Must generate id="{{ refView }}" element which
         will hold contents of referenced model. Its class must be is
         {{ refClass }}.

         "{{ refView }}-perms" will be used for instance permissions.

         May setup on-demand loading function.
    -->
    <script type="text/template"
            class="reference-template"
            id="services-reference-template">
      <div class="accordion-group">
        <div class="accordion-heading">
          <a class="accordion-toggle"
             id="{{ refView }}-link"
             data-bind="text: modelTitle"
             data-target="#{{ refView }}-head"
             data-toggle="collapse">Услуга…</a>
        </div>

        <div id="{{ refView }}-head"
             class="accordion-body collapse in">
          <div class="accordion-inner {{ refClass }}" 
               id="{{ refView }}">
            <!-- Instance contents are rendered here -->

          </div>
        </div>
      </div>
    </script>

    <script type="text/template"
            class="reference-template"
            id="actions-reference-template">
      <div class="accordion-group">
        <div class="accordion-heading">
          <a class="accordion-toggle"
             id="{{ refView }}-link"
             data-bind="text: nameLocal"
             data-target="#{{ refView }}-head"
             data-toggle="collapse">Действие…</a>
        </div>

        <div id="{{ refView }}-head"
             class="accordion-body collapse {{^refId}}in{{/refId}}">
          <div class="accordion-inner {{ refClass }}" 
               id="{{ refView }}">
            <!-- Instance contents are rendered here -->

          </div>
        </div>
      </div>
    </script>

    <!-- Group view container -->
    <script type="text/template"
            class="group-template"
            id="-group-template">
      <fieldset class="complex-field"
                id="{{ refView }}"
                style="display: none;">
          <i class="icon icon-remove complex-field-close"
             onclick="hideComplex()"/>
          <form class="content form-vertical"/>
      </fieldset>
    </script>

    <!-- Template for fields with unknown type -->
    <script type="text/template"
            class="field-template"
            id="unknown-field-template">
      <div class="control-group">
        <div class="controls">
          <span class="label label-important">
            (Ошибка — поле {{ name }} неизвестного типа)
          </span>
        </div>
      </div>
    </script>

    <!-- Form controls wrt user permissions -->
    <script type="text/template"
            id="permission-template">
        {{# readonly }}
        <button class="btn disabled" type="button">
          <i class="icon-ban-circle" /> Только для чтения</button>
        {{/ readonly }}
        {{^ readonly }}
        <button class="btn btn-success" type="button"
                onClick="saveInstance('{{ viewName }}');successfulSave.call(this);">
          <i class="icon-pencil icon-white" /> Сохранить</button>
          <span class="save-result"/>
        {{/ readonly }}
    </script>

    <!-- List of empty required fields -->
    <script type="text/template"
            id="empty-fields-template">
      <ul id="empty-fields">
      {{# fields }}
      <li onclick="focusField('{{name}}'); return false;"
          data-bind="css: { lierror: {{name}}Not }, visible: {{name}}Not">{{meta.label}}</li>
      {{/ fields }}
      </ul>
    </script>

    <!-- Render service picker with services dictionary -->
    <script type="text/template"
            id="service-picker-template">
      <ul class="nav nav-pills">
        <li class="dropdown">
          <button class="dropdown-toggle btn btn-action"
                  type="button"
                  data-toggle="dropdown">
            <i class="icon icon-plus" />Добавить услугу
          </button>
          <ul class="dropdown-menu">
            {{# dictionary.entries }}
            <li>
              <a href="#" onclick="addService('{{value}}');">
                <i class="icon-{{icon}} icon-black" />
                {{ label }}
              </a>
            </li>
            {{/ dictionary.entries }}
          </ul>
        </li>
      </ul>
    </script>

    <script type="text/template"
            id="check-list-item-template">
      <li><input type="checkbox" /> {{ label }}</li>
    </script>

    <!-- Fallback template for pickTemplate failures -->
    <script type="text/template"
            id="unknown-template">
      <span class="label label-important">
        Не удалось найти ни один из шаблонов:
        {{#names}}{{.}}&nbsp;{{/names}}
      </span>
    </script>

    <!-- File upload template -->
    <script type="text/template"
            class="field-template"
            id="files-field-template">
      <label>{{ meta.label }}</label>
      <form data-bind="attr: { action: {{name}}UploadUrl }, setdata: {{name}}"
            method="post"
            enctype="multipart/form-data">
        <input type="file" name="files" />
        <input type="button" value="Загрузить" onClick="uploadFile(this)" />
      </form>
    </script>

    <!-- Default case group view template -->
    <script type="text/template"
            class="group-template"
            id="default-case-group-template">
      <fieldset class="complex-field default-complex-field"
                id="default-case-complex-field">
         <div class="program">
           <h1 data-bind="text: programLocal"></h1>
           <div data-bind="html:programDesc"></div>
           <br />
           <br />
          <div data-bind="foreach: servicesDescs">
            <dt data-bind="text: title"></dt>
            <dd data-bind="html: description"></dd>
          </div>
          <br />
          <h4>Загруженные файлы:</h4>
          <ul class="unstyled" data-bind="foreach: filesInfo">
            <li>
              <a data-bind="attr: { href: url }, text: name" />
            </li>
          </ul>
        </div>
      </fieldset>
    </script>

  </body>
</html>
