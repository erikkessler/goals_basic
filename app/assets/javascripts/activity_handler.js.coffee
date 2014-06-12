# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

checkboxChange= ->
        $.ajax
                url: "/toggle/" + $(this).attr('value') + ".js"

todaymenuShow = (param) ->
        position = $("#task_1").position()
        styles = { "display": "", "left": position.left, "top": position.top }
        $(".today-menu-container").css(styles)

todaymenuHide= ->
        if !$(".today-menu-container").is(":hover") 
                $(".today-menu-container").css("display", "none")
        
        
$(document).on "ready page:load", ->
        $(".today-menu-container").css("display", "none")
        
        $("#name").focus()
        $(".shown_form").show()
        $(".shown_form_title").css("font-weight","Bold")
        $(".hidden_form").hide()
        $(".hidden_form_title").css("font-weight","Normal")
        $("#task").click ->
                console.log("Task clicked")
                $("#task_form").show()
                $("#task").css("font-weight","Bold")
                $("#habit_form").hide()
                $("#habit").css("font-weight","Normal")
        $("#habit").click ->
                console.log("Habit clicked")
                $("#task_form").hide()
                $("#task").css("font-weight","Normal")
                $("#habit_form").show()
                $("#habit").css("font-weight","Bold")
        $(".show-menu-marker").hoverIntent({
                over: ->
                        position = $(this).position()
                        styles = { "display": "", "left": position.left, "top": position.top }
                        $(".today-menu-container").css(styles).attr("index", $(this).attr('id').substring(7))
                out: todaymenuHide
                sensitivity: 2
                timeout: 1000
                })
        $(".today-menu-container").hoverIntent({
                out: ->
                        $(this).css("display", "none")
                timeout: 1000
                })

$ ->
        $(document).on 'change', '.task_checkbox', checkboxChange

        $(document).on 'click', '#today-menuitem-view', ->
                window.location = '/activity_handler/' + $(".today-menu-container").attr("index")
        $(document).on 'click', '#today-menuitem-edit', ->
                window.location = '/activity_handler/' + $(".today-menu-container").attr("index") + '/edit'
        $(document).on 'click', '#today-menuitem-remove', ->
                $.ajax
                        url: '/activity_handler/' + $(".today-menu-container").attr("index") + '.js'
                        type: 'DELETE'
                
       
