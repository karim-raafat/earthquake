import 'package:earthquake/pages/settings_page.dart';
import 'package:earthquake/providers/app_data_provider.dart';
import 'package:earthquake/utils/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void didChangeDependencies() {
    Provider.of<AppDataProvider>(context, listen: false).init();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earthquake App'),
        actions: [
          IconButton(onPressed: _showSortingDialog, icon: const Icon(Icons.sort)),
          IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage())),
              icon: const Icon(Icons.settings)),
        ],
      ),
      body: Consumer<AppDataProvider>(
          builder: (context, provider, child) => provider.hasDataLoaded
              ? provider.earthquakeModel!.features!.isEmpty
                  ? const Center(
                      child: Text('No record has been found'),
                    )
                  : ListView.builder(
                      itemCount: provider.earthquakeModel!.features!.length,
                      itemBuilder: (context, index) {
                        final data = provider.earthquakeModel!.features![index].properties!;
                        return ListTile(
                          onTap: (){
                            _launchUrl(provider.earthquakeModel!.features![index].geometry!.coordinates!);
                          },
                          title: Text(data.place ?? data.title ?? 'Unknown'),
                          subtitle: Text(getFormattedDateTime(data.time!, 'EEE MMM dd yyyy hh:mm a')),
                          trailing: Chip(
                            avatar: data.alert == null
                                ? null
                                : CircleAvatar(
                                    backgroundColor: provider.getAlertColor(data.alert!),
                                  ),
                            label: Text('${data.mag}'),
                          ),
                        );
                      },
                    )
              : const Center(
                  child: Text('Please wait...'),
                )),
    );
  }

  _showSortingDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Sort by'),
              content: Consumer<AppDataProvider>(
                builder: (BuildContext context, provider, Widget? child) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioGroup(
                      groupValue: provider.orderBy,
                      value: 'magnitude',
                      label: 'Magnitude - Desc',
                      onChanged: (value) {
                        provider.orderBy = value!;
                      },
                    ),
                    RadioGroup(
                      groupValue: provider.orderBy,
                      value: 'magnitude-asc',
                      label: 'Magnitude - Asc',
                      onChanged: (value) {
                        provider.orderBy = value!;
                      },
                    ),
                    RadioGroup(
                      groupValue: provider.orderBy,
                      value: 'time',
                      label: 'Time - Desc',
                      onChanged: (value) {
                        provider.orderBy = value!;
                      },
                    ),
                    RadioGroup(
                      groupValue: provider.orderBy,
                      value: 'time-asc',
                      label: 'Time - Asc',
                      onChanged: (value) {
                        provider.orderBy = value!;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ],
            ));
  }




  Future<void> _launchUrl(List<num> coordinates) async {
    final url = Uri.parse('https://www.google.com/maps?q=${coordinates[0]},${coordinates[1]}');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}

class RadioGroup extends StatelessWidget {
  final String groupValue;
  final String value;
  final String label;
  final Function(String?) onChanged;

  const RadioGroup(
      {super.key, required this.groupValue, required this.value, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged),
        Text(label),
      ],
    );
  }
}
