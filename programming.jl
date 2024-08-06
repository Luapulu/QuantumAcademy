### A Pluto.jl notebook ###
# v0.19.45

using Markdown
using InteractiveUtils

# ╔═╡ e783f975-198a-4887-8b73-09f80b061fc3
using LinearAlgebra: dot

# ╔═╡ 16ddedcf-79a8-41c4-8adf-48b8f60bfb9f
using LinearAlgebra: norm

# ╔═╡ 32acc50c-541e-11ef-1e9a-c1069fdd881e
md"# Goals

This notebook is an introduction to all the basic programming concepts that you'll need for this course. We're going to go through a series of exercises, which always have the same format:

 1. We introduce a concept, such as vectors, if-statements, for loops, and many more by explaining it in detail, and providing a link to the Julia documentation that you can check for any remaining questions.

2. We show an example exercise with the solution provided, so you can see the concept in action. 

3. You are given a similar exercise, which you can use to check your understanding and apply what you've just learnt.

This notebook is also intended as a script, which you can use to remind yourself of these concepts (and the syntax) whenever needed.
The solutions to the exercises are already in the notebook in hidden cells (can be revealed by clicking the little eye icon to the left of the cell). Please don't look at it before seriously trying to solve the exercise, and of course ask us for hints if you're stuck. Check your work using the solution, and if you get too frustrated, you can of course look at it and try to understand it; We'll happily give you another similar question to check your understanding if you ask."

# ╔═╡ 7e5d7d9f-424a-42bc-823f-6d8b75d22b69
md"## Variables
We start by defining variables. These can hold different types of values, such as integers, floats, and true/false (bools). What you need to pay attention to, is that which values can be given to a variable depends on the datatype it was assigned. [link to manual section on variables](https://docs.julialang.org/en/v1/manual/variables/)"

# ╔═╡ d45f6dd6-3eec-4176-b68b-49fa2c5686b8
this_is_a_int = 3

# ╔═╡ db8d3eb1-a6a3-49f1-bd1f-e8e025168b74
this_is_a_float = 3.0

# ╔═╡ 92f1cae5-5c3b-4a11-9ae9-6856e4276343
this_is_a_bool = true

# ╔═╡ 42b7bde1-10f5-48cb-b883-72d29e3ff8e6
this_is_a_string = "This is a string"

# ╔═╡ 0451d304-249f-46fd-bee8-1f0571aa5c91
md"### Example 1: 
Create a string and get the type of the variable using the [`typeof`](https://docs.julialang.org/en/v1/base/base/#Core.typeof) function. "

# ╔═╡ eb48a227-bf65-465c-ad02-ff0f0046837c
ex_str = "Hello world"

# ╔═╡ 3adf7dbd-932d-4333-8a5d-c49fa39281c3
typeof(ex_str)

# ╔═╡ 2a24c387-35df-45e1-baa8-6f57176a604d
md"### Exercise 1:
Create an `Int` and get the type of the variable using the `typeof` function. Then turn it into a 64-bit-float by applying the `Float64` function to it. "

# ╔═╡ 176b2bae-57cd-4c81-8326-52fb7624f79c
ex_int = 5

# ╔═╡ ad743ddd-232e-4ee8-b4cc-68c1d4386fa2
typeof(ex_int)

# ╔═╡ b81ba794-dbd1-4389-8a64-533c76810978
Float64(ex_int)

# ╔═╡ 987f82e2-f5c9-4b9a-9b1f-865e4985c524
md"### Complex numbers

As a quick reminder: A complex number can be defined using two real numbers:"

# ╔═╡ 73566eb3-9cb9-4c30-999b-e56a4d3c53e2
realpart = 5.0

# ╔═╡ 0b227bfa-5c1c-469a-b7db-51b301fb8352
imagpart = 3.0

# ╔═╡ 5aab52ce-e210-435c-93c2-3e92c99ebd3c
complexnumber = realpart + imagpart*im

# ╔═╡ f43f1564-7e07-4111-a64d-870e7b0ee571
typeof(complexnumber)

# ╔═╡ e8c39614-96d8-4924-8798-21d37268a5b9
md"## Calculating things
The kinds of variables we'll be using the most are Integers (Int) and Floats. These are useful for calculating things, and we can perform operations such as addition, subtraction and multiplication. 
In these notebooks, we can simply perform these operations, and see the output above the cell; In general, we usually want a program to do things automatically, so we need to define new variables which are assigned the outputs of the calculations. "

# ╔═╡ fd9f86a5-8639-4f47-9e34-5d3a0150c805
x1 = 10

# ╔═╡ ed053319-7333-4511-91d8-c91155abde8a
x2 = 5.0

# ╔═╡ ad848334-6456-47f5-9ff1-96f9fd02bba7
x1 + x2

# ╔═╡ bd9a3bbb-9264-4a15-b66e-f862a04ecf41
md"### Example 2: 
Sum the variables x1 and x2, and write the output to a third variable. Then multiply all three variables"

# ╔═╡ 4ca3e5b5-b19e-4e7b-ba37-5d135e3e3e92
x_ex2 = x1 + x2

# ╔═╡ 048aa52b-9f21-4b8b-aa78-27ecfc38bd9c
x_ex2*x1*x2

# ╔═╡ 2e868722-1ff4-4237-9870-441e3e274cc4
md"### Exercise 2:
Divide x1 by x2 and output the solution into a third variable you define. Note that in Pluto-notebooks you can not overwrite the values of variables with a single statement in a cell; Doing so will disable the cell in which it was originally defined, and may break some of your code. "

# ╔═╡ 12435800-5900-4192-9772-5bc05b804bb1
x_exer2=x1/x2

# ╔═╡ 023bc213-029a-40e3-b91b-14059f37fc5f
md"## Functions
A function is a block of code which can be executed in any place inside the notebook by calling its name [manual section on function](https://docs.julialang.org/en/v1/manual/functions/). The syntax for a simple function is "

# ╔═╡ a245673e-9ad9-4016-a6e4-8da8101f9602
function example_function1(argument1, argument2, argument3)
	helper_variable = argument1 + argument2
	return helper_variable * argument3
end

# ╔═╡ e8bfa8f9-b7e8-4bc6-aec9-9bda697d3ae9
md"The arguments are names for variables which are passed to your function. Note that the number of arguments is arbitrary when defining the function, but when calling the exact amount of arguments needs to be given, as the function was defined with. The syntax for calling the function above is"

# ╔═╡ 213f666e-5bdc-4026-92d8-9f66fa82550b
example_function1(2,6,13)

# ╔═╡ 17c2655f-ec5e-44ea-b209-aaa3ace17817
md"### Example 3:
Define a function which takes two numbers, and returns their sum. After that, call it with the values 2 and 3 as arguments. "

# ╔═╡ b37cfc0f-dde4-4459-ba75-57e45024195f
function add(n1, n2)
	return n1 + n2
end

# ╔═╡ 77a01984-d513-450f-addb-cc525bd34f8c
add(2, 3)

# ╔═╡ ced4324e-bfdd-4236-ab02-1c2a0e3cc620
md"One thing to note: Variables defined inside the function only exist for that function. They can not be accessed from outside the function, and you can define variables with the same name elsewhere. However, global variables (Variables that were defined somewhere in the notebook) can also be accessed from inside functions.

Generally, you want to avoid touching global variables within functions. Global variables make code harder to debug and degrade performance.
"

# ╔═╡ e420def1-990c-4539-92a1-a6a84131794b
function globalproblems()
	print(x1)
end

# ╔═╡ 38ce800b-8d77-456b-9c2f-9f74645f7386
globalproblems()

# ╔═╡ 7f3067c4-5880-4dab-a01c-01f3649129c9
md"### Exercise 3:
Define a function which takes three numbers. It adds the first two together, and then divides the resulting number by the third argument. Then call this function for the values 4, 6, 11."

# ╔═╡ 558aac8f-e008-4a54-a5cc-32a12bc93ea9
function exercise3_sol(n1,n2,n3)
	helper = n1 + n2
	return helper / n3
end

# ╔═╡ 4aa1e083-bf2c-4fe1-aee2-e1172103492b
exercise3_sol(4,6,11)

# ╔═╡ e9a14a86-4050-472a-af2c-eb99dc0a238c
md"You cannot change a global variable inside a function, so you can name a variable inside the function the same as a global variable without worrying about affeting the global variable."

# ╔═╡ 3696577e-f6d7-4e51-806b-181ecf4c8a58
md"## If and Else

If-statements are very useful when coding, as they allow you to write code that does different things depending on some condition. [Manual section on control flow](https://docs.julialang.org/en/v1/manual/control-flow/). For example, you may want to check if a variable is larger than 10, and then tell the user."

# ╔═╡ 99f816cf-94fe-46c2-a6b6-0f0b546d332d
x3 = 15

# ╔═╡ cb1c63e6-109d-4b06-8903-6638f8e6ad8e
if x3 > 10
	print("The variable is larger than 10")
end

# ╔═╡ 58811327-f7e3-42a6-a829-29e05fd41097
md"However, you also may want to do something, if the conidition is not fullfilled. This is what the `else` statement is for:"

# ╔═╡ dbea6b8c-bfd6-46cf-b859-0d0f28f30421
if x3 > 10
	print("The variable is larger than 10")
else
	print("The variable is smaller than or equal to 10")
end

# ╔═╡ 8ec5305c-1e29-482f-8e05-235390af069f
md"Sometimes there is more than one condition to check. Then you will want to use `elseif`:"

# ╔═╡ d5e44b30-cdde-4fc6-b9eb-ae26cae9f8ca
if x3 > 10
	print("The variable is larger than 10")
elseif x3 < 10
	print("The variable is smaller than 10")
else
	print("The variable is ten")
end

# ╔═╡ 7ce4b025-f7bb-49ae-a175-b40077a6afb3
md"The operators for checking if a number is larger or smaller are of course > and <; However, you can also check equality with == in exactly the same way. You can check if two variables are not the same with !="

# ╔═╡ 28cc5ee2-2c96-47a0-afcc-11ad1b884cb3
md"### Example 4:
Implement a function, which takes two arguments and compares them. If the first argument is larger, print 'quite a large first argument we have here'. If the second is larger, return the value 10. If the third is larger, do both, taking care to print before the return statement, as code after it will not be executed."

# ╔═╡ 0634df8c-5840-4ec4-b93a-6cc714ef0783
function example4(n1, n2)
	if n1 > n2
		print("Quite a large first argument we have here")
	elseif n2 > n1
		return 10
	else
		print("Quite a large first argument we have here")
		return 10
	end
end

# ╔═╡ 38a3a9e8-47a2-4355-a87d-1abb010bf6a7
md"### Exercise 4:
Implement a function which outputs the larger of two arguments given to it, and returns their sum if they are equal. However, if one of the arguments is 10, print \"Hoooray, a 10\" and return 20."

# ╔═╡ 5643adf0-3c75-4fdb-bcd4-3831ca53aa8f
function exercise_4_sol(n1,n2)
	if n1 == 10
		print("Hoooray, a 10")
		return 20
	elseif n2 == 10
		print("Hoooray, a 10")
		return 20
	end
	if n1 > n2
		return n1
	elseif n2 > n1
		return n2
	else
		return n1 + n2
	end
end

# ╔═╡ ff0fde47-31f6-4900-a585-d2310c489894
md"Sometimes it can be useful to use a shorthand expression for an if else expression. The example below returns 3 if x < 1 and 5 otherwise. If you see `condition ? x : y` it means if the condition is true, return x, else y. [link to docs for the ternary operator](https://docs.julialang.org/en/v1/base/base/#?:)."

# ╔═╡ 9cff528f-b4ac-452d-ae34-52e5a6bcbb1a
ternary(x) = x < 1 ? 3 : 5

# ╔═╡ 57765137-e134-4a40-820e-79467fa14755
ternary(0.5)

# ╔═╡ 6e086d2d-1f5c-4605-b929-dcc68873b37a
md"## Vectors
A vector is a collection of variables stored in a single-dimensional grid. The generalisation, the array, stores vectors in a multi-dimensional grid. However, we will mostly be concerned with 1- and 2 dimensional arrays. 
In order to initialize a vector, you can write"

# ╔═╡ b62b130b-4180-4e04-a72e-7f22cf067386
firstvector = [1, 2, 3, 4, 6]

# ╔═╡ 43781eb3-7eb7-4c87-ada0-74d5174a11af
typeof(firstvector)

# ╔═╡ ff7ca778-27f2-4a48-a597-bec4543c25e6
eltype(firstvector)

# ╔═╡ a20731ba-c626-4e2b-826b-f0f0c1cb152e
length(firstvector)

# ╔═╡ e402bc16-3000-4f44-a48f-9ec8ca83f755
md"You can also add more entries to a vector using `push!()`"

# ╔═╡ 8a9576cc-1fdf-4a98-9eaf-512f5dc8a3be
push!(firstvector, 1)

# ╔═╡ f5914a69-ee17-43b4-b7d1-6fa2ef23d78a
firstvector # As you can see, the vector has now permanently added one entry with value 1. 

# ╔═╡ 7887280b-40ae-4697-88f0-4743ab74bfc9
md"You can add vectors together, as long as they have the same length"

# ╔═╡ e28707a3-7d8d-4696-aa5e-96c58f86ae74
secondvector = [1, 2, 3, 4, 5, 6]

# ╔═╡ eea68886-d40e-4865-a429-b6bf37562759
firstvector + secondvector

# ╔═╡ 04681d96-3d37-43ae-a819-5cb52a3c76eb
md"You can calculate their scalar product using dot(), if import it from the LinearAlgebra package"

# ╔═╡ 7d2d9538-81be-4688-94a7-4f38c3b5e647
dot(firstvector, secondvector)

# ╔═╡ e736766a-7fb5-4fbd-9523-93da3625cfe2
md"You can import the entire package with `import LinearAlgebra`, but that would take a while, so we don't do it here. "

# ╔═╡ 760c62ab-32fc-4e45-b4c5-6aeca2f05079
md"You can calculate the norm with the LinearAlgebra function norm()"

# ╔═╡ 93c47440-2699-4ebd-bd97-ca45633cf4ad
norm(firstvector)

# ╔═╡ 0a103a65-e3bb-409f-9dca-d63f922da6f1
md"A useful convenience is taking the adjoint of the vector:"

# ╔═╡ ed2fd893-309c-4dfa-8069-270c34e11bba
firstvector'

# ╔═╡ a370107e-8169-4cf9-b2ad-db99f2258dd9
md"This allows directly calculating the scalar product:"

# ╔═╡ 04363f29-adba-4f5f-a3fe-7aeecfbc059c
firstvector'*secondvector

# ╔═╡ 44ea8436-ee09-41e0-9015-a56a9e32ee9d
md"### Example 5:
Write a function that calculates the sum of two vectors."

# ╔═╡ c1447501-9177-42b1-b262-dad0bb252b7e
function Example5(v,w)
	return v + w
end

# ╔═╡ 5e8e4e2c-953d-4d1f-82a4-71f8b60247a7
md"### Exercise 5:
Write a function that calculates the dot product of two vectors, and outputs the first if the scalar product is larger than 10, and the second if it is smaller. Note that, because we imported the function dot() above, it can be used anywhere in the notebook, including inside functions. "

# ╔═╡ eef5e915-5eee-485d-9327-34cf69a8cd5b
function Exercise5_sol(v,w)
	scalar_prod = dot(v,w)
	if scalar_prod > 10
		return v
	elseif scalar_prod < 10
		return w
	else
		print("The Question didn't ask you to do anything in this case. What does your function do?")
	end
end

# ╔═╡ fc8b899a-1e7a-43e8-8673-d7f39a784611
Exercise5_sol([1,1], [2,2])

# ╔═╡ 14e750a6-cdf2-458d-be2c-50beb4fc751a
Exercise5_sol([10,10], [11,11])

# ╔═╡ e0983425-36e3-4de4-a13c-29183621ee4d
Exercise5_sol([10,0], [1,0])

# ╔═╡ ec023baa-c63e-46fa-b89c-3104cc219112
md"## Matrices

A matrix is like a vector, except the list of values is indexed in two dimensions instead of only one. You can imagine them as a grid of values. They can be defined as: "

# ╔═╡ 8f5b5422-12f7-4bc6-b05c-2a1d44f18d1a
firstmatrix = [1 2 3 ; 4 5 6 ; 7 8 9]

# ╔═╡ 3b439150-ff63-4554-9d66-7a3f7a3317ba
md"We can get the size of the matrix (how many entries in each direction):"

# ╔═╡ 619b7000-d774-485f-98c3-72a1ad2a40b1
size(firstmatrix)

# ╔═╡ 29a5abb4-96dd-4647-904d-7e070192a897
size(firstmatrix,1)

# ╔═╡ 538b0fe5-0ecd-4b3e-8d32-defa9477369e
md"We can add matrices together element-wise:"

# ╔═╡ 01d31d3a-40ea-4858-9230-118a7637a16c
secondmatrix = [1 0 0 ; 0 1 0 ; 0 0 1]

# ╔═╡ f790b1d0-b05a-4718-80ec-c453db25a310
firstmatrix + secondmatrix 

# ╔═╡ 2b6793ad-1da2-458c-b28e-a004e11978ce
md"If we just multiply them, Julia automatically does matrix multiplication: "

# ╔═╡ 85c10351-b671-46d0-92a0-209cd02ec81e
firstmatrix * firstmatrix

# ╔═╡ 0faa44bb-8eba-453f-ba32-c39f9566205a
md"However, we can also multiply them element-wise:"

# ╔═╡ 3485195d-1e53-4a98-ab57-0ba672dadc4a
firstmatrix .* firstmatrix

# ╔═╡ a7fa2604-0d7b-41f8-8e2e-852c98781dd1
md"And we can do matrix-vector multiplication:"

# ╔═╡ 32a5d222-1fa1-49ff-91ee-6980ad6697b2
threevector = [1,2,3]

# ╔═╡ fd44fd24-f378-4eba-adde-b874d519f783
firstmatrix * threevector

# ╔═╡ 9efa7d61-7067-43e2-8b2a-bd9915cb641a
md"### Example 6:
Initialize a matrix, and multiply it element-wise with itself, then perform matrix multiplication of the result and the original matrix. "

# ╔═╡ 3c08abb7-4757-4470-a1d5-80b141a9f57d
example_matrix = [1 1 1; 2 2 2; 3 3 3]

# ╔═╡ e683d99f-ec45-447d-a81b-7f18172aaa96
(example_matrix .* example_matrix)*example_matrix

# ╔═╡ ffb5f032-0c99-437c-801c-d0e1a8afc678
md"### Exercise 6:
Write a function which takes a vector, multiplies it with a matrix of your choosing, and then calculates the norm of the vector and returns that"

# ╔═╡ 584d795c-6265-4550-9a34-d8fc6b908c8e
function Exercise6_sol(v)
	mymatrix = [2 0 0 ; 0 2 0 ; 0 0 2]
	return norm(mymatrix*v)
end

# ╔═╡ 6dbec45a-d28e-494b-97a2-1d653d79eb0c
md"## For-loops

We now arrive at the final and most important building block for writing basic Julia code - The for-loop. This is similar to if-else statements, in that it belongs to the category of control flow [manual section on control flow](https://docs.julialang.org/en/v1/manual/control-flow/#man-loops). 
We use the foor loop when we want to repeatedly perform the same instruction. The simplest example would be writing the same text several times:"

# ╔═╡ 0927f93a-a186-481a-aa6b-43b224e13b02
for i in 1:10
	println("Hello World")
end

# ╔═╡ 6b24d03f-7f4c-47c7-8d35-a1c3fb6553b5
md"Above, we use the notation 1:10 to create an array with 10 entries, going from 1 to zero:"

# ╔═╡ 8c17182e-08e9-44c4-9c65-5280139f5ab1
collect(1:10) #We need to use collect() to actually see the elements of the array, because Julia doesn't internally create the actual array as a vector

# ╔═╡ cc5acd32-367b-4c9e-bc08-b4f9b357b2c7
md"In the for-loop, the variable i is assigned the first value of the array 1:10, then the code in the loop is executed. This is repeated in sequence for all elements of the array. We can see this by printing i for every iteration:"

# ╔═╡ 87738bff-04de-41fc-be9c-d68effc15ce7
for i in 1:10
	println("i is ",i)
end

# ╔═╡ c06f395c-03c0-4bba-8d3d-8d309e9e8dab
md"If we want to count down instead, we can use"

# ╔═╡ 015e8e1f-ed2b-4031-aaaf-708fddc73728
for i in 10:-1:1
	println("i is ",i)
end

# ╔═╡ 66ab1d94-8072-4df2-81eb-52401b7bf7fa
md"We can also use completely different ways of counting:"

# ╔═╡ 37b4ef8b-fc7e-4b9f-9983-dd1303d0f950
for i in 1:4:10
	println("i is ",i)
end

# ╔═╡ b20b2b4b-cc04-447d-80d7-3c14305dff73
md"As you can see, the first number sets the starting value, the second sets the step size (increase if positive, decrease if negative), and the last sets the largest possible value. The final value is not always the same as the largest possible value."

# ╔═╡ 2d2512dd-664e-4144-8eff-e9c2ac3f0cbd
md"### Example 6:
Write a function to calculate the sum of all elements of a vector with any length"

# ╔═╡ d0418419-e07c-4c66-af4b-849db6842a84
function Example6(v)
	len = length(v)
	summer = 0
	for i in 1:len
		summer = summer + v[i]
	end
	return summer
end

# ╔═╡ 44d90f2e-59ef-4a31-91a8-c0efe811f1ae
Example6([1,2,3,4,5])

# ╔═╡ 9a6bde50-c4f2-4ab4-8e97-1237ebc98c02
Example6([1,2,3,4])

# ╔═╡ cd8ad71a-734b-40b9-9b86-153e83650318
md"### Exercise 7:
Write a function which calculates the sum of squares of all elements, except for the 7th, of a vector if any length."

# ╔═╡ f0d39e3f-309c-412d-b9dd-434714da7912
function Exercise7_sol(v)
	len = length(v)
	summer = 0
	for i in 1:len
		if i != 7
			summer = summer + v[i]
		end
	end
	return summer
end

# ╔═╡ 7184e7d0-7ec7-4feb-80d3-1c22de6bc49b
Exercise7_sol([1,2,3,4,5,6,7])

# ╔═╡ 6db42547-1ec6-4032-bfc3-5413b055db5a
Exercise7_sol([1,2,3,4,5,6])

# ╔═╡ c59ca493-e091-4598-b262-413296a4cf08
md"### Iterating over other arrays
We can also iterate over other arrays than the ones we define explicitly for the for-loop. Any array can be iterated over. "

# ╔═╡ 47f86849-fd45-4d32-94cc-4a05d62abfc5
for i in firstvector
	println("This is an element of firstvector ",i)
end

# ╔═╡ 7f73a7ff-fc69-4642-bf1d-1adf00a4fc2b
firstvector

# ╔═╡ 4b39200d-5c52-4263-8ce5-ee94e8967461
md"As you can see above, the variable i then takes the value of each element of `firstvector` in sequence."

# ╔═╡ 38ff494d-59b9-4c25-93b1-206e528e5b8a
md"### Example 8

Sum over the squares of all values in a vector (in a function)."

# ╔═╡ 74f9a406-3d08-4ff3-8abc-5519e540333d
function Example8(v)
	summer = 0
	for i in v
		summer = summer + i
	end
	return summer
end

# ╔═╡ b8df3fa4-43e2-47e4-9034-3d8c4a103be0
Example8([1,1,1,1,1])

# ╔═╡ 374638f6-e97c-4e7d-bc4a-ee0d642e93c1
md"### Exercise 8:

Calculate norm of a vector, without using the built-in functions like norm(). As a reminder, to calculate the norm, you first sum over the squares of all elements of the vector, and then take the square root of that sum. You can square a number in Julia with number^2 and you can take the square root with sqrt(number)."

# ╔═╡ 1a22cce2-8f38-4ca6-8ea3-22d645d9bd1b
function Exercise8_sol(v)
	summer = 0
	for i in v
		summer = summer + i^2
	end
	return sqrt(summer)
end

# ╔═╡ 7f40b5ca-3007-4182-9fa2-e497e400cf4c
Exercise8_sol([1,1,1,1,1])

# ╔═╡ 09aecd96-e429-4c5e-8d3d-1f7bbeaccd1b
md"### Exercise 9:

Calculate scalar product of two vectors, without using the built-in functions like dot(). As a reminder, to calculate the scalar product, you sum over the products of all elements of the vectors."

# ╔═╡ b235070b-348b-462a-94bf-5c72929a96b9
function Exercise9_sol(v,w)
	len = length(v)
	checklen = length(w)
	if len == checklen
		summer = 0
		for i in 1:len
			summer = summer + conj(v[i])*w[i]
		end
	end
	return summer
end

# ╔═╡ 072a9065-36c6-4c7c-b805-f5c492b351db
Exercise9_sol([1 0], [0 1])

# ╔═╡ 69b1e8d0-5338-4d2a-bd9c-f4332a89aee1
md"### Exercise 10:

Calculate matrix-vector product of a matrix and a vector, without using the built-in functions like *. Check the definition of the matrix-vector product first!"

# ╔═╡ 58f1d071-8aea-47ff-8fb4-ba9d23fed6a1
function Exercise10_sol(A,v)
	len = length(v)
	checklen = size(A,2)
	output = []
	if len == checklen
		for i in 1:len
			summer = 0
			for j in 1:len
				summer = summer + A[i,j]*v[j]
			end
			push!(output,summer)
		end
	end
	return output
end

# ╔═╡ e57cac00-99c2-41b7-9425-5b25798310a6
size([1 1; 1 1])[1]

# ╔═╡ 4d42d32d-2fd4-45af-8609-17055a6451bd
Exercise10_sol([1 1 ; 1 1], [0 1])

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.3"
manifest_format = "2.0"
project_hash = "ac1187e548c6ab173ac57d4e72da1620216bce54"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"
"""

# ╔═╡ Cell order:
# ╟─32acc50c-541e-11ef-1e9a-c1069fdd881e
# ╠═7e5d7d9f-424a-42bc-823f-6d8b75d22b69
# ╠═d45f6dd6-3eec-4176-b68b-49fa2c5686b8
# ╠═db8d3eb1-a6a3-49f1-bd1f-e8e025168b74
# ╠═92f1cae5-5c3b-4a11-9ae9-6856e4276343
# ╠═42b7bde1-10f5-48cb-b883-72d29e3ff8e6
# ╟─0451d304-249f-46fd-bee8-1f0571aa5c91
# ╠═eb48a227-bf65-465c-ad02-ff0f0046837c
# ╠═3adf7dbd-932d-4333-8a5d-c49fa39281c3
# ╟─2a24c387-35df-45e1-baa8-6f57176a604d
# ╟─176b2bae-57cd-4c81-8326-52fb7624f79c
# ╟─ad743ddd-232e-4ee8-b4cc-68c1d4386fa2
# ╟─b81ba794-dbd1-4389-8a64-533c76810978
# ╠═987f82e2-f5c9-4b9a-9b1f-865e4985c524
# ╠═73566eb3-9cb9-4c30-999b-e56a4d3c53e2
# ╠═0b227bfa-5c1c-469a-b7db-51b301fb8352
# ╠═5aab52ce-e210-435c-93c2-3e92c99ebd3c
# ╠═f43f1564-7e07-4111-a64d-870e7b0ee571
# ╟─e8c39614-96d8-4924-8798-21d37268a5b9
# ╠═fd9f86a5-8639-4f47-9e34-5d3a0150c805
# ╠═ed053319-7333-4511-91d8-c91155abde8a
# ╠═ad848334-6456-47f5-9ff1-96f9fd02bba7
# ╠═bd9a3bbb-9264-4a15-b66e-f862a04ecf41
# ╠═4ca3e5b5-b19e-4e7b-ba37-5d135e3e3e92
# ╠═048aa52b-9f21-4b8b-aa78-27ecfc38bd9c
# ╟─2e868722-1ff4-4237-9870-441e3e274cc4
# ╟─12435800-5900-4192-9772-5bc05b804bb1
# ╟─023bc213-029a-40e3-b91b-14059f37fc5f
# ╠═a245673e-9ad9-4016-a6e4-8da8101f9602
# ╟─e8bfa8f9-b7e8-4bc6-aec9-9bda697d3ae9
# ╠═213f666e-5bdc-4026-92d8-9f66fa82550b
# ╟─17c2655f-ec5e-44ea-b209-aaa3ace17817
# ╠═b37cfc0f-dde4-4459-ba75-57e45024195f
# ╠═77a01984-d513-450f-addb-cc525bd34f8c
# ╟─ced4324e-bfdd-4236-ab02-1c2a0e3cc620
# ╠═e420def1-990c-4539-92a1-a6a84131794b
# ╠═38ce800b-8d77-456b-9c2f-9f74645f7386
# ╟─7f3067c4-5880-4dab-a01c-01f3649129c9
# ╟─558aac8f-e008-4a54-a5cc-32a12bc93ea9
# ╟─4aa1e083-bf2c-4fe1-aee2-e1172103492b
# ╟─e9a14a86-4050-472a-af2c-eb99dc0a238c
# ╟─3696577e-f6d7-4e51-806b-181ecf4c8a58
# ╠═99f816cf-94fe-46c2-a6b6-0f0b546d332d
# ╠═cb1c63e6-109d-4b06-8903-6638f8e6ad8e
# ╟─58811327-f7e3-42a6-a829-29e05fd41097
# ╠═dbea6b8c-bfd6-46cf-b859-0d0f28f30421
# ╟─8ec5305c-1e29-482f-8e05-235390af069f
# ╠═d5e44b30-cdde-4fc6-b9eb-ae26cae9f8ca
# ╟─7ce4b025-f7bb-49ae-a175-b40077a6afb3
# ╟─28cc5ee2-2c96-47a0-afcc-11ad1b884cb3
# ╠═0634df8c-5840-4ec4-b93a-6cc714ef0783
# ╟─38a3a9e8-47a2-4355-a87d-1abb010bf6a7
# ╟─5643adf0-3c75-4fdb-bcd4-3831ca53aa8f
# ╟─ff0fde47-31f6-4900-a585-d2310c489894
# ╠═9cff528f-b4ac-452d-ae34-52e5a6bcbb1a
# ╠═57765137-e134-4a40-820e-79467fa14755
# ╟─6e086d2d-1f5c-4605-b929-dcc68873b37a
# ╠═b62b130b-4180-4e04-a72e-7f22cf067386
# ╠═43781eb3-7eb7-4c87-ada0-74d5174a11af
# ╠═ff7ca778-27f2-4a48-a597-bec4543c25e6
# ╠═a20731ba-c626-4e2b-826b-f0f0c1cb152e
# ╠═e402bc16-3000-4f44-a48f-9ec8ca83f755
# ╠═8a9576cc-1fdf-4a98-9eaf-512f5dc8a3be
# ╠═f5914a69-ee17-43b4-b7d1-6fa2ef23d78a
# ╟─7887280b-40ae-4697-88f0-4743ab74bfc9
# ╠═e28707a3-7d8d-4696-aa5e-96c58f86ae74
# ╠═eea68886-d40e-4865-a429-b6bf37562759
# ╠═04681d96-3d37-43ae-a819-5cb52a3c76eb
# ╠═e783f975-198a-4887-8b73-09f80b061fc3
# ╠═7d2d9538-81be-4688-94a7-4f38c3b5e647
# ╟─e736766a-7fb5-4fbd-9523-93da3625cfe2
# ╠═760c62ab-32fc-4e45-b4c5-6aeca2f05079
# ╠═16ddedcf-79a8-41c4-8adf-48b8f60bfb9f
# ╠═93c47440-2699-4ebd-bd97-ca45633cf4ad
# ╠═0a103a65-e3bb-409f-9dca-d63f922da6f1
# ╠═ed2fd893-309c-4dfa-8069-270c34e11bba
# ╠═a370107e-8169-4cf9-b2ad-db99f2258dd9
# ╠═04363f29-adba-4f5f-a3fe-7aeecfbc059c
# ╟─44ea8436-ee09-41e0-9015-a56a9e32ee9d
# ╠═c1447501-9177-42b1-b262-dad0bb252b7e
# ╟─5e8e4e2c-953d-4d1f-82a4-71f8b60247a7
# ╠═eef5e915-5eee-485d-9327-34cf69a8cd5b
# ╟─fc8b899a-1e7a-43e8-8673-d7f39a784611
# ╟─14e750a6-cdf2-458d-be2c-50beb4fc751a
# ╟─e0983425-36e3-4de4-a13c-29183621ee4d
# ╟─ec023baa-c63e-46fa-b89c-3104cc219112
# ╠═8f5b5422-12f7-4bc6-b05c-2a1d44f18d1a
# ╟─3b439150-ff63-4554-9d66-7a3f7a3317ba
# ╠═619b7000-d774-485f-98c3-72a1ad2a40b1
# ╠═29a5abb4-96dd-4647-904d-7e070192a897
# ╠═538b0fe5-0ecd-4b3e-8d32-defa9477369e
# ╠═01d31d3a-40ea-4858-9230-118a7637a16c
# ╠═f790b1d0-b05a-4718-80ec-c453db25a310
# ╠═2b6793ad-1da2-458c-b28e-a004e11978ce
# ╠═85c10351-b671-46d0-92a0-209cd02ec81e
# ╠═0faa44bb-8eba-453f-ba32-c39f9566205a
# ╠═3485195d-1e53-4a98-ab57-0ba672dadc4a
# ╠═a7fa2604-0d7b-41f8-8e2e-852c98781dd1
# ╠═32a5d222-1fa1-49ff-91ee-6980ad6697b2
# ╠═fd44fd24-f378-4eba-adde-b874d519f783
# ╠═9efa7d61-7067-43e2-8b2a-bd9915cb641a
# ╠═3c08abb7-4757-4470-a1d5-80b141a9f57d
# ╠═e683d99f-ec45-447d-a81b-7f18172aaa96
# ╟─ffb5f032-0c99-437c-801c-d0e1a8afc678
# ╟─584d795c-6265-4550-9a34-d8fc6b908c8e
# ╟─6dbec45a-d28e-494b-97a2-1d653d79eb0c
# ╠═0927f93a-a186-481a-aa6b-43b224e13b02
# ╟─6b24d03f-7f4c-47c7-8d35-a1c3fb6553b5
# ╠═8c17182e-08e9-44c4-9c65-5280139f5ab1
# ╠═cc5acd32-367b-4c9e-bc08-b4f9b357b2c7
# ╠═87738bff-04de-41fc-be9c-d68effc15ce7
# ╠═c06f395c-03c0-4bba-8d3d-8d309e9e8dab
# ╠═015e8e1f-ed2b-4031-aaaf-708fddc73728
# ╠═66ab1d94-8072-4df2-81eb-52401b7bf7fa
# ╠═37b4ef8b-fc7e-4b9f-9983-dd1303d0f950
# ╟─b20b2b4b-cc04-447d-80d7-3c14305dff73
# ╠═2d2512dd-664e-4144-8eff-e9c2ac3f0cbd
# ╠═d0418419-e07c-4c66-af4b-849db6842a84
# ╠═44d90f2e-59ef-4a31-91a8-c0efe811f1ae
# ╠═9a6bde50-c4f2-4ab4-8e97-1237ebc98c02
# ╟─cd8ad71a-734b-40b9-9b86-153e83650318
# ╟─f0d39e3f-309c-412d-b9dd-434714da7912
# ╟─7184e7d0-7ec7-4feb-80d3-1c22de6bc49b
# ╟─6db42547-1ec6-4032-bfc3-5413b055db5a
# ╟─c59ca493-e091-4598-b262-413296a4cf08
# ╠═47f86849-fd45-4d32-94cc-4a05d62abfc5
# ╠═7f73a7ff-fc69-4642-bf1d-1adf00a4fc2b
# ╟─4b39200d-5c52-4263-8ce5-ee94e8967461
# ╟─38ff494d-59b9-4c25-93b1-206e528e5b8a
# ╠═74f9a406-3d08-4ff3-8abc-5519e540333d
# ╠═b8df3fa4-43e2-47e4-9034-3d8c4a103be0
# ╠═374638f6-e97c-4e7d-bc4a-ee0d642e93c1
# ╟─1a22cce2-8f38-4ca6-8ea3-22d645d9bd1b
# ╟─7f40b5ca-3007-4182-9fa2-e497e400cf4c
# ╠═09aecd96-e429-4c5e-8d3d-1f7bbeaccd1b
# ╟─b235070b-348b-462a-94bf-5c72929a96b9
# ╟─072a9065-36c6-4c7c-b805-f5c492b351db
# ╠═69b1e8d0-5338-4d2a-bd9c-f4332a89aee1
# ╟─58f1d071-8aea-47ff-8fb4-ba9d23fed6a1
# ╟─e57cac00-99c2-41b7-9425-5b25798310a6
# ╟─4d42d32d-2fd4-45af-8609-17055a6451bd
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
