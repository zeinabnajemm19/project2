import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RecipeSearchScreen(),
    );
  }
}

class RecipeSearchScreen extends StatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  _RecipeSearchScreenState createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  String? selectedCategory;
  String? selectedDuration;
  List<Recipe> recipes = [];
  List<Recipe> filteredRecipes = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final uri = Uri.parse('http://192.168.56.1/recipe_app/get_recipes.php');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        if (data is List) {
          setState(() {
            recipes = data.map((json) => Recipe.fromJson(json)).toList();
            filteredRecipes = List.from(recipes);
          });
        } else {
          setState(() {
            errorMessage = 'Unexpected data format';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load recipes: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching recipes: ${e.toString()}';
        print('Error fetching recipes: ${e.toString()}');
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterRecipes() {
    setState(() {
      filteredRecipes = recipes.where((recipe) {
        final matchesCategory =
            selectedCategory == null || recipe.category == selectedCategory;
        final matchesDuration =
            selectedDuration == null || recipe.duration == selectedDuration;
        return matchesCategory && matchesDuration;
      }).toList();
    });
  }

  void showRecipeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtered Recipes'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = filteredRecipes[index];
                return ListTile(
                  title: Text(recipe.name),
                  subtitle: Text('${recipe.category}, ${recipe.duration}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void showSearchDialog() {
    TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Recipe'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(hintText: 'Enter recipe name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String searchTerm = searchController.text.toLowerCase();
                List<Recipe> searchResults = recipes.where((recipe) {
                  return recipe.name.toLowerCase().contains(searchTerm);
                }).toList();

                Navigator.of(context).pop(); // Close the search dialog
                showSearchResultsDialog(searchResults);
              },
              child: const Text('Search'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void showSearchResultsDialog(List<Recipe> searchResults) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Results'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final recipe = searchResults[index];
                return ListTile(
                  title: Text(recipe.name),
                  subtitle: Text('${recipe.category}, ${recipe.duration}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Happy Kids Meal',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : Column(
        children: [
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.topRight,
            children: [
              Image.asset(
                '../assets/BackgroundEraser_20240909_152450763.png',
                height: 300,
              ),
              IconButton(
                icon: const Icon(Icons.search, size: 30),
                onPressed: showSearchDialog,
                tooltip: 'Search Recipe',
              ),
            ],
          ),
          DropdownButton<String>(
            value: selectedCategory,
            hint: const Text('Choose a Category'),
            items: recipes
                .map((recipe) => recipe.category)
                .toSet()
                .map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
                filterRecipes();
              });
            },
          ),
          const SizedBox(height: 10),
          const Text('Select Duration:'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['10 mins', '20 mins', '30 mins', '45 mins']
                .map((duration) {
              return Flexible(
                child: RadioListTile<String>(
                  title: Text(duration),
                  value: duration,
                  groupValue: selectedDuration,
                  onChanged: (value) {
                    setState(() {
                      selectedDuration = value;
                      filterRecipes();
                    });
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: showRecipeDialog,
            child: const Text('Show Recipes'),
          ),
        ],
      ),
    );
  }
}

class Recipe {
  final int id;
  final String category;
  final String name;
  final String duration;

  Recipe({
    required this.id,
    required this.category,
    required this.name,
    required this.duration,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: (json['id'] != null) ? int.parse(json['id'].toString()) : 0,
      category: json['category'] ?? 'Unknown',
      name: json['name'] ?? 'Untitled',
      duration: json['duration'] ?? 'Not specified',
    );
  }
}