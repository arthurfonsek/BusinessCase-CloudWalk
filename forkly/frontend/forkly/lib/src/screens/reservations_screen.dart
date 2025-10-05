import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/auth_service_simple.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({Key? key}) : super(key: key);

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final Api _api = Api();
  final AuthService _authService = AuthService();
  List<dynamic> _restaurants = [];
  List<dynamic> _myReservations = [];
  List<dynamic> _restaurantReservations = [];
  bool _isLoading = true;
  String? _error;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      await _authService.initialize();
      _isOwner = _authService.currentUser?.role.isRestaurantOwner == true;
      if (_isOwner) {
        final reservations = await _api.getRestaurantReservations();
        setState(() {
          _restaurantReservations = reservations;
          _isLoading = false;
        });
      } else {
        final restaurants = await _api.getRestaurantsWithReservations();
        final reservations = await _api.getMyReservations();
        setState(() {
          _restaurants = restaurants;
          _myReservations = reservations;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOwner) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reservas do Restaurante'),
          backgroundColor: const Color(0xFFd60000),
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        const Text('Erro ao carregar dados'),
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  )
                : _buildRestaurantReservationsList(),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reservas'),
          backgroundColor: const Color(0xFFd60000),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Fazer Reserva', icon: Icon(Icons.add)),
              Tab(text: 'Minhas Reservas', icon: Icon(Icons.book_online)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        const Text('Erro ao carregar dados'),
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildRestaurantsTab(),
                      _buildMyReservationsTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildRestaurantsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = _restaurants[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFd60000),
                child: Icon(
                  Icons.restaurant,
                  color: Colors.white,
                ),
              ),
              title: Text(restaurant['name'] ?? 'Nome não informado'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant['address'] ?? 'Endereço não informado'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${restaurant['rating_avg']?.toStringAsFixed(1) ?? '0.0'}'),
                      const SizedBox(width: 16),
                      Icon(Icons.attach_money, color: Colors.green, size: 16),
                      Text('${restaurant['price_level'] ?? 0}'),
                    ],
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => _showReservationDialog(restaurant),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd60000),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reservar'),
              ),
              onTap: () => _showReservationDialog(restaurant),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyReservationsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _myReservations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma reserva encontrada',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Faça sua primeira reserva!',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myReservations.length,
              itemBuilder: (context, index) {
                final reservation = _myReservations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(reservation['status']),
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(reservation['restaurant_name'] ?? 'Restaurante'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${reservation['date']} às ${reservation['time']}'),
                        Text('${reservation['party_size']} pessoas'),
                        if (reservation['special_requests']?.isNotEmpty == true)
                          Text(
                            'Pedidos especiais: ${reservation['special_requests']}',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        _getStatusText(reservation['status']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: _getStatusColor(reservation['status']),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRestaurantReservationsList() {
    if (_restaurantReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma reserva encontrada para seu restaurante',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _restaurantReservations.length,
        itemBuilder: (context, index) {
          final reservation = _restaurantReservations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(reservation['status']),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(reservation['customer_username'] ?? 'Cliente'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${reservation['date']} às ${reservation['time']}'),
                  Text('${reservation['party_size']} pessoas'),
                  if (reservation['special_requests']?.isNotEmpty == true)
                    Text(
                      'Pedidos: ${reservation['special_requests']}',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              trailing: Chip(
                label: Text(
                  _getStatusText(reservation['status']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: _getStatusColor(reservation['status']),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showReservationDialog(Map<String, dynamic> restaurant) {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final partySizeController = TextEditingController();
    final specialRequestsController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reservar em ${restaurant['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Data (DD/MM/AAAA)',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    dateController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Horário (HH:MM)',
                  prefixIcon: Icon(Icons.access_time),
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: partySizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de pessoas',
                  prefixIcon: Icon(Icons.people),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: specialRequestsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Pedidos especiais (opcional)',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _createReservation(
              restaurant,
              dateController.text,
              timeController.text,
              partySizeController.text,
              phoneController.text,
              emailController.text,
              specialRequestsController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFd60000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Reserva'),
          ),
        ],
      ),
    );
  }

  Future<void> _createReservation(
    Map<String, dynamic> restaurant,
    String date,
    String time,
    String partySize,
    String phone,
    String email,
    String specialRequests,
  ) async {
    try {
      // Parse date
      final dateParts = date.split('/');
      final reservationDate = DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
      );

      // Parse time
      final timeParts = time.split(':');
      final reservationTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );

      await _api.createReservation(
        restaurant['id'],
        reservationDate,
        reservationTime,
        int.parse(partySize),
        phone: phone.isNotEmpty ? phone : null,
        email: email.isNotEmpty ? email : null,
        specialRequests: specialRequests.isNotEmpty ? specialRequests : null,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva criada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar reserva: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'no_show':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmada';
      case 'completed':
        return 'Concluída';
      case 'cancelled':
        return 'Cancelada';
      case 'no_show':
        return 'Não compareceu';
      default:
        return status;
    }
  }
}
