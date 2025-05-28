import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:proyecto_recetas/models/ingredient.dart';
import 'package:proyecto_recetas/models/user.dart';
import 'package:proyecto_recetas/services/local_db_service.dart';
import 'package:proyecto_recetas/services/constants.dart';

class StatisticsScreen extends StatefulWidget {
  final UserModel user;

  const StatisticsScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Ingredient> _topIngredients = [];
  Map<String, int> _weeklyRecipes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final topIngredients =
          LocalDBService().getMostUsedIngredients(widget.user.id);
      final weeklyRecipes =
          LocalDBService().getWeeklyRecipeCount(widget.user.id);

      setState(() {
        _topIngredients = topIngredients;
        _weeklyRecipes = weeklyRecipes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Estadísticas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ingredientes más usados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPieChart(),
                    const SizedBox(height: 16),
                    _buildTopIngredientsList(),
                    const SizedBox(height: 24),
                    const Text(
                      'Recetas semanales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBarChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPieChart() {
    if (_topIngredients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No hay suficientes datos para mostrar el gráfico',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: _getIngredientSections(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          startDegreeOffset: 180,
        ),
      ),
    );
  }

  List<PieChartSectionData> _getIngredientSections() {
    final List<Color> colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    return List.generate(
      _topIngredients.length > 5 ? 5 : _topIngredients.length,
      (index) {
        final ingredient = _topIngredients[index];
        return PieChartSectionData(
          color: colors[index % colors.length],
          value: 1,
          title: '',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildTopIngredientsList() {
    if (_topIngredients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No hay ingredientes para mostrar',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      );
    }

    final List<Color> colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 10 Ingredientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              _topIngredients.length,
              (index) {
                final ingredient = _topIngredients[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ingredient.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (_weeklyRecipes.values.every((count) => count == 0)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No hay recetas esta semana',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxRecipeCount() + 1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final weekdays = [
                    'Lun',
                    'Mar',
                    'Mié',
                    'Jue',
                    'Vie',
                    'Sáb',
                    'Dom'
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      weekdays[value.toInt()],
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.background,
                strokeWidth: 1,
              );
            },
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: _getBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    final weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];

    return List.generate(7, (index) {
      final count = _weeklyRecipes[weekdays[index]] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  double _getMaxRecipeCount() {
    if (_weeklyRecipes.isEmpty) return 1;
    return _weeklyRecipes.values.reduce((a, b) => a > b ? a : b).toDouble();
  }
}
