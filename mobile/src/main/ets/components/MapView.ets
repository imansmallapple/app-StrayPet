// MapView Component - Mapbox GL JS via WebView
// Following ArkTS strict typing rules

import { webview } from '@kit.ArkWeb';

// Map marker data structure
export class MapMarker {
  id: number = 0;
  latitude: number = 0;
  longitude: number = 0;
  title: string = '';
  description: string = '';
  type: string = 'default'; // 'lost', 'shelter', 'pet'
  color: string = '#FF6B35';
  imageUrl: string = '';

  constructor(id: number = 0, lat: number = 0, lng: number = 0, title: string = '') {
    this.id = id;
    this.latitude = lat;
    this.longitude = lng;
    this.title = title;
  }
}

@Component
export struct MapView {
  @Prop markers: MapMarker[] = [];
  @Prop centerLat: number = 39.9042; // Default: Beijing
  @Prop centerLng: number = 116.4074;
  @Prop zoom: number = 10;
  @Prop mapboxToken: string = ''; // Mapbox public token
  
  private controller: webview.WebviewController = new webview.WebviewController();
  @State isLoading: boolean = true;
  
  private onMarkerClick?: (marker: MapMarker) => void;

  setOnMarkerClickListener(callback: (marker: MapMarker) => void): void {
    this.onMarkerClick = callback;
  }

  // Generate marker JavaScript
  private generateMarkersScript(): string {
    let script = '';
    for (let i = 0; i < this.markers.length; i++) {
      const m = this.markers[i];
      const popupContent = `<strong>${m.title}</strong>${m.description.length > 0 ? '<br/>' + m.description : ''}`;
      script += `
        new mapboxgl.Marker({ color: '${m.color}' })
          .setLngLat([${m.longitude}, ${m.latitude}])
          .setPopup(new mapboxgl.Popup().setHTML('${popupContent.replace(/'/g, "\\'")}'))
          .addTo(map);
      `;
    }
    return script;
  }

  // Generate the full HTML for Mapbox
  private generateMapHtml(): string {
    const markersScript = this.generateMarkersScript();
    
    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="initial-scale=1,maximum-scale=1,user-scalable=no">
  <link href="https://api.mapbox.com/mapbox-gl-js/v3.0.1/mapbox-gl.css" rel="stylesheet">
  <script src="https://api.mapbox.com/mapbox-gl-js/v3.0.1/mapbox-gl.js"></script>
  <style>
    body { margin: 0; padding: 0; }
    #map { position: absolute; top: 0; bottom: 0; width: 100%; }
    .mapboxgl-popup-content { padding: 10px 15px; border-radius: 8px; }
    .mapboxgl-popup-content strong { color: #212121; }
    .loading-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: #f5f5f5;
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
    }
    .loading-overlay.hidden { display: none; }
  </style>
</head>
<body>
  <div id="loading" class="loading-overlay">
    <span style="color: #757575;">Loading map...</span>
  </div>
  <div id="map"></div>
  <script>
    mapboxgl.accessToken = '${this.mapboxToken}';
    
    const map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/mapbox/streets-v12',
      center: [${this.centerLng}, ${this.centerLat}],
      zoom: ${this.zoom}
    });
    
    map.addControl(new mapboxgl.NavigationControl());
    map.addControl(new mapboxgl.GeolocateControl({
      positionOptions: { enableHighAccuracy: true },
      trackUserLocation: true
    }));
    
    map.on('load', function() {
      document.getElementById('loading').classList.add('hidden');
      ${markersScript}
      
      // Fit bounds to markers if there are any
      ${this.markers.length > 1 ? `
      const bounds = new mapboxgl.LngLatBounds();
      ${this.markers.map(m => `bounds.extend([${m.longitude}, ${m.latitude}]);`).join('\n')}
      map.fitBounds(bounds, { padding: 50 });
      ` : ''}
    });
  </script>
</body>
</html>`;
  }

  // Refresh map with new markers
  updateMarkers(newMarkers: MapMarker[]): void {
    // Reload the webview with new data
    const html = this.generateMapHtml();
    this.controller.loadData(html, 'text/html', 'UTF-8', '');
  }

  aboutToAppear(): void {
    // Pre-generate HTML
    console.info('[MapView] aboutToAppear, token length:', this.mapboxToken.length);
  }

  build() {
    Stack() {
      Web({ src: '', controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .geolocationAccess(true)
        .mixedMode(MixedMode.All)
        .onControllerAttached(() => {
          // Load the map HTML when controller is attached
          console.info('[MapView] Controller attached, loading map...');
          const html = this.generateMapHtml();
          this.controller.loadData(html, 'text/html', 'UTF-8', '');
        })
        .onPageBegin(() => {
          console.info('[MapView] Page begin loading');
          this.isLoading = true;
        })
        .onPageEnd(() => {
          console.info('[MapView] Page end loading');
          this.isLoading = false;
        })
        .onErrorReceive((event) => {
          console.error('[MapView] Error:', JSON.stringify(event));
        })
        .width('100%')
        .height('100%')

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#FF6B35')
          Text('Loading map...')
            .fontSize(14)
            .fontColor('#757575')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F5F5F5')
      }
    }
    .width('100%')
    .height('100%')
  }
}
