# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

checkboxChange= ->
        $.ajax
                url: "/toggle/" + $(this).attr('value') + ".js"
                
$(document).on "ready page:load", ->
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

$ ->
        $(document).on 'change', '.task_checkbox', checkboxChange
                
       
