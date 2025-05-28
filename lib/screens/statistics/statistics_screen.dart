import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/database_service.dart';

class StatisticsScreen extends StatefulWidget {
  final String userId;
  
  const StatisticsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, int> _topIngredients = {};
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
      final topIngredients = DatabaseService().getMostUsedIngredients(widget.userId);
      final weeklyRecipes = DatabaseService().getWeeklyRecipeCount(widget.userId);
      
      setState(() {
        _topIngredients = topIngredients;
        _weeklyRecipes = weeklyRecipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar estadísticas: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Estadísticas')),
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildPieChart(),
                    const SizedBox(height: 16),
                    _buildTopIngredientsList(),
                    const SizedBox(height: 24),
                    const Text(
                      'Recetas semanales',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          child: Text('No hay datos suficientes para mostrar el gráfico'),
        ),
      );
    }
    
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: _getPieChartSections(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
  
  List<PieChartSectionData> _getPieChartSections() {
    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.red];
    final entries = _topIngredients.entries.take(5).toList();
    
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }
  
  Widget _buildTopIngredientsList() {
    if (_topIngredients.isEmpty) {
      return const Center(
        child: Text('No hay ingredientes para mostrar'),
      );
    }
    
    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.red];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top 10 Ingredientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(_topIngredients.length, (index) {
              final entry = _topIngredients.entries.elementAt(index);
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
                    Expanded(child: Text(entry.key)),
                    Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBarChart() {
    if (_weeklyRecipes.values.every((count) => count == 0)) {
      return const Center(
        child: Text('No hay recetas esta semana'),
      );
    }
    
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxRecipeCount() + 1,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                  return Text(weekdays[value.toInt()], style: const TextStyle(fontSize: 12));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 12));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _getBarGroups(),
        ),
      ),
    );
  }
  
  List<BarChartGroupData> _getBarGroups() {
    final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    
    return List.generate(7, (index) {
      final count = _weeklyRecipes[weekdays[index]] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: Colors.green,
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
