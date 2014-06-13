@redmine_time_tracker ?= {}
class @redmine_time_tracker.TimeTracker
  @hideMultiFormButtons: (button_class) ->
    last = $("input.#{button_class}").parent().parent().last().index()
    $("input." + button_class).each ->
      unless last is $(@).parent().parent().index()
        $(this).hide()
      else
        $(this).show()

  @base_url: ->
    src = $("link[href*=\"time_tracker.css\"]")[0].href
    src.substr 0, src.indexOf("plugin_assets")

  @validate_time_tracker_form: ->
    proj_field = $ '#time_tracker_project_id'
    activity_select = $ '#time_tracker_activity_id'
    proj_id = proj_field.val()
    activity_id = activity_select.val()
    activity_select.toggleClass 'invalid', proj_id isnt "" and activity_id is ""
    $(".time-tracker-form :submit").attr "disabled", $(".time-tracker-form :input").hasClass("invalid")

  @updateBookingHours: (name) ->
    start = timeString2min($("#" + name + "_start_time").val())
    stop = timeString2min($("#" + name + "_stop_time").val())

    # if the stop-time is smaller than the start-time, we assume a booking over midnight
    $("#" + name + "_spent_time").val min2timeString(stop + ((if stop < start then 1440 else 0)) - start)
    (new redmine_time_tracker.ListInputValidator(name)).validate()

  @updateBookingStop: (name) ->
    start = timeString2min($("#" + name + "_start_time").val())
    spent_time = timeString2min($("#" + name + "_spent_time").val())
    $("#" + name + "_stop_time").val min2parsedTimeString((start + spent_time) % 1440)
    (new redmine_time_tracker.ListInputValidator(name)).validate()

  @updateBookingProject: (api_key, name) ->
    issue_id_field = $("#" + name + "_issue_id")
    project_id_field = $("#" + name + "_project_id")
    project_id_select = $("#" + name + "_project_id_select")
    issue_id = issue_id_field.val()

    # check if the string is blank
    if not issue_id or $.trim(issue_id) is ""
      project_id_select.attr "disabled", false
      issue_id_field.removeClass "invalid"
      (new redmine_time_tracker.ListInputValidator(name)).validate()
    else
      $.ajax
        url: @base_url() + "issues/" + issue_id + ".json?key=" + api_key
        type: "GET"
        success: (transport) =>
          issue_id_field.removeClass "invalid"
          issue = transport.issue
          unless issue?
            project_id_select.attr "disabled", false
          else
            project_id_select.attr "disabled", true
            project_id_field.val issue.project.id
            $("#" + project_id_select.attr("id")).val issue.project.id
          @updateBookingActivity api_key, name

        error: ->
          project_id_select.attr "disabled", false
          issue_id_field.addClass "invalid"

        complete: ->
          (new redmine_time_tracker.ListInputValidator(name)).validate()

  @updateBookingActivity: (api_key, name) ->
    $.ajax
      url: @base_url() + "tt_completer/get_activity.json?key=" + api_key + "&project_id=" + $("#" + name + "_project_id").val()
      type: "GET"
      success: (activites) =>
        activity_field = $("#" + name + "_activity_id_select")
        selected_activity = activity_field.find("option:selected").text()
        activity_field.find("option[value!=\"\"]").remove()
        $.each activites, (i, activity) ->
          activity_field.append "<option value=\"" + activity.id + "\">" + activity.name + "</option>"
          activity_field.val activity.id  if selected_activity is activity.name

        (new redmine_time_tracker.ListInputValidator(name)).validate()

$ ->
  $(document).on "ajax:success", ".tt_stop, .tt_start, .tt_dialog_stop", (xhr, html, status) ->
    $("#content .flash").remove()
    $("#content").prepend html

  $(document).on "ajax:success", ".tt_stop, .tt_start, .tt_dialog_stop", (xhr, html, status) ->
    $("#content .flash").remove()
    $("#content").prepend html

  $(document).on "ajax:success", ".tt_stop, .tt_start, .tt_dialog_stop", (xhr, html, status) ->
    $("#content .flash").remove()
    $("#content").prepend html
  redmine_time_tracker.TimeTracker.validate_time_tracker_form()