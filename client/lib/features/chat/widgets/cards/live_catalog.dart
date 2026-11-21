import 'package:a2ui_flutter/a2ui_flutter.dart';

import 'live_composed.dart';
import 'live_fares.dart';
import 'live_money.dart';
import 'live_time.dart';
import 'live_tools.dart';
import 'live_weather.dart';
import 'live_world.dart';

/// Live data cards, composed cards and containers (docs/RICH-CARDS-PLAN.md). Apps from before them
/// leave them out of the card; the bot always says a line in text too.
final liveComponents = <ComponentImplementation>[
  weatherComponent,
  forecastComponent,
  weatherAlertComponent,
  airQualityComponent,
  sunMoonComponent,
  quoteComponent,
  watchlistComponent,
  currencyComponent,
  worldClockComponent,
  countdownComponent,
  holidaysComponent,
  quakeComponent,
  stormComponent,
  scoreComponent,
  standingsComponent,
  flightComponent,
  faresComponent,
  parcelComponent,
  summaryComponent,
  definitionComponent,
  mediaComponent,
  recipeComponent,
  comparisonComponent,
  prosConsComponent,
  stepsComponent,
  timelineComponent,
  calculatorComponent,
  randomComponent,
  translationComponent,
  contactComponent,
  quizComponent,
  nutritionComponent,
  statusComponent,
  dashboardComponent,
  carouselComponent,
];
