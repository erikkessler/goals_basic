# types
Type.destroy_all
basic_tasks = Type.create([
             {name:'Contained Task', description:
               'A single-time task that is complete only when all its children are.', type_id: 0},
             {name:'External Task', description:
               'A single-time task that is not necessarily complete if its children are. ', type_id: 1}])

habits = Type.create([
             {name:'Habit', description:
               'A repeated task that has no inherent goal or end date.', type_id: 2},
             {name:'Habit with Target Number', description:
               'A repeated task that has to be completed a certain number of times to be complete.', type_id: 3},
             {name:'Habit with Number/Week', description:
               'A repeated task where you set the number of times it must be completed in the week and the number of weeks that you must reach that per week target.', type_id: 4}])

goals = Type.create([
             {name:'Goal', description:
               'The most generic type of goal. There is no tracking; you have to say when it is done.', type_id: 5},
             {name:'Goal: Summing/Subtracting to a Target', description:
               'Goal where you record your progress. When your progress sums/subtracts to your goal it automatically marks it as complete.', type_id: 6},
             {name:'Goal: Average', description:
               'Goal where you record your progress. When you reach your check in date, it automatically marks it as complete if you are at or better than your goal average.', type_id: 7},
             {name:'Goal: Max/Min', description:
               'Goal where you record your progress. Trying to reach a maximum or minimum goal.', type_id: 8}])

# type_groups
TypeGroup.destroy_all
basic_group = TypeGroup.create(name: 'Basic Task',  
                               description: 'Single time tasks')
basic_group.types << basic_tasks

habit_group = TypeGroup.create(name: 'Habit',
                               description: 'Repeated tasks')
habit_group.types << habits

goal_group = TypeGroup.create(name: 'Goal',
                              description: 'Long term, short term, and weekly')
goal_group.types << goals

# handler
if ActivityHandler.all.size == 0
  ActivityHandler.create(reset_date: Date.new(2014,6,22), upto_date: Date.new(2014,7,6))
end

