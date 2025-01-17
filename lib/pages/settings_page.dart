import 'package:earthquake/providers/app_data_provider.dart';
import 'package:earthquake/utils/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AppDataProvider>(
        builder: (BuildContext context, provider, Widget? child) => ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            Text(
              'Time Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      'Start Time',
                    ),
                    subtitle: Text(provider.startTime),
                    trailing: IconButton(
                        onPressed: () async {
                          final date = await selectDate();
                          if (date != null) {
                            provider.startTime = date;
                          }
                        },
                        icon: Icon(Icons.calendar_month)),
                  ),
                  ListTile(
                    title: const Text(
                      'End Time',
                    ),
                    subtitle: Text(provider.endTime),
                    trailing: IconButton(
                        onPressed: () async {
                          final date = await selectDate();
                          if (date != null) {
                            provider.endTime = date;
                          }
                        },
                        icon: Icon(Icons.calendar_month)),
                  ),
                ],
              ),
            ),
            Text(
              'Location Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              height: 100,
              child: Card(
                child: Center(
                  child: SwitchListTile(
                    title: Text(provider.currentCity ?? 'Your Location is Unknown'),
                    subtitle: (provider.currentCity == null)
                        ? null
                        : (provider.currentCity == '')
                            ? Text('Earthquake data will be shown ${provider.maxRadiusKm} from your current location')
                            : Text(
                                'Earthquake data will be shown within ${provider.maxRadiusKm} km radius from ${provider.currentCity}'),
                    value: provider.shouldUseLocation,
                    onChanged: (value) async {
                      EasyLoading.show(status: 'Getting your location...');
                      await provider.setLocation(value);
                      EasyLoading.dismiss();
                    },
                  ),
                ),
              ),
            ),
            Text(
              'Magnitude Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Card(
              child: Column(
                children: [
                  Slider(
                    value: provider.minMagnitude.toDouble(),
                    min: 0,
                    max: 8,
                    onChanged: (value) {
                      provider.minMagnitude = value.round();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('Minimum Magnitude : ${provider.minMagnitude}'),
                  ),
                ],
              ),
            ),
            Text(
              'Radius Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Card(
              child: Column(
                children: [
                  Slider(
                    value: provider.maxRadiusKm,
                    min: 500,
                    max: provider.maxRadiusKmThreshold,
                    divisions: (provider.maxRadiusKmThreshold) ~/ 0.01,
                    onChanged: (value) {
                      provider.maxRadiusKm = double.parse((value).toStringAsFixed(2));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('Radius: ${provider.maxRadiusKm} km'),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                provider.getEarthquakeData();
                showMsg(context, 'Changes are applied');
              },
              child: const Text('Apply Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> selectDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (dt != null) {
      return getFormattedDateTime(dt.millisecondsSinceEpoch);
    }
    return null;
  }
}
