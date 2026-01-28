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

  // Generate marker JavaScript with click handlers
  private generateMarkersScript(): string {
    let script = '';
    for (let i = 0; i < this.markers.length; i++) {
      const m = this.markers[i];
      const popupContent = `<strong>${m.title}</strong>${m.description.length > 0 ? '<br/>' + m.description : ''}`;
      // 为每个标记添加点击事件，通过 JSBridge 与原生通信
      script += `
        (function() {
          const marker = new mapboxgl.Marker({ color: '${m.color}' })
            .setLngLat([${m.longitude}, ${m.latitude}])
            .setPopup(new mapboxgl.Popup({ offset: 25 }).setHTML('${popupContent.replace(/'/g, "\\'")}'))
            .addTo(map);
          
          marker.getElement().addEventListener('click', function() {
            // 发送消息到原生层
            window.postMessage && window.postMessage(JSON.stringify({
              type: 'markerClick',
              markerId: ${m.id},
              lat: ${m.latitude},
              lng: ${m.longitude},
              title: '${m.title.replace(/'/g, "\\'")}'
            }));
          });
        })();
      `;
    }
    return script;
  }

  // Generate the full HTML for Mapbox
  private generateMapHtml(): string {
    const markersScript = this.generateMarkersScript();
    
    // 使用最新的 Mapbox GL JS v3.18.1
    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="initial-scale=1,maximum-scale=1,user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: #f5f5f5; }
    #map { position: absolute; top: 0; bottom: 0; left: 0; right: 0; width: 100%; height: 100%; }
    .mapboxgl-popup-content { padding: 10px 15px; border-radius: 8px; }
    .mapboxgl-popup-content strong { color: #212121; }
    .loading-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: #f5f5f5;
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
      flex-direction: column;
    }
    .loading-overlay.hidden { display: none; }
    .error-message {
      color: #F44336;
      font-size: 14px;
      text-align: center;
      padding: 20px;
    }
    .status-text {
      color: #757575;
      font-size: 13px;
      margin-top: 8px;
    }
  </style>
</head>
<body>
  <div id="loading" class="loading-overlay">
    <span style="color: #757575;">Loading map...</span>
    <span id="status" class="status-text">Initializing...</span>
  </div>
  <div id="map"></div>
  
  <script>
    // 更新状态显示
    function updateStatus(msg) {
      console.log('[Map] ' + msg);
      var el = document.getElementById('status');
      if (el) el.textContent = msg;
    }
    
    updateStatus('Loading Mapbox scripts...');
  </script>
  
  <!-- 加载 Mapbox CSS -->
  <link href="https://api.mapbox.com/mapbox-gl-js/v3.18.1/mapbox-gl.css" rel="stylesheet">
  
  <!-- 加载 Mapbox JS -->
  <script src="https://api.mapbox.com/mapbox-gl-js/v3.18.1/mapbox-gl.js" onload="initMap()" onerror="scriptError('mapbox-gl.js')"></script>
  
  <script>
    function scriptError(name) {
      updateStatus('Failed to load: ' + name);
      document.getElementById('loading').innerHTML = '<div class="error-message">Failed to load ' + name + '<br><br>Please check your network connection</div>';
    }
    
    function initMap() {
      updateStatus('Mapbox loaded, initializing map...');
      
      try {
        if (typeof mapboxgl === 'undefined') {
          throw new Error('mapboxgl is undefined');
        }
        
        mapboxgl.accessToken = '${this.mapboxToken}';
        updateStatus('Token set, checking WebGL...');
        
        if (!mapboxgl.supported()) {
          throw new Error('WebGL not supported');
        }
        
        updateStatus('Creating map instance...');
        
        const map = new mapboxgl.Map({
          container: 'map',
          style: 'mapbox://styles/mapbox/streets-v12',
          center: [${this.centerLng}, ${this.centerLat}],
          zoom: ${this.zoom},
          attributionControl: true,
          failIfMajorPerformanceCaveat: false
        });
        
        updateStatus('Map created, waiting for style...');
        
        map.on('style.load', function() {
          updateStatus('Style loaded');
        });
        
        map.on('load', function() {
          console.log('[Map] Map loaded successfully');
          updateStatus('Map ready!');
          document.getElementById('loading').classList.add('hidden');
          ${markersScript}
          
          ${this.markers.length > 1 ? `
          var bounds = new mapboxgl.LngLatBounds();
          ${this.markers.map(m => `bounds.extend([${m.longitude}, ${m.latitude}]);`).join('\n')}
          map.fitBounds(bounds, { padding: 50 });
          ` : ''}
          
          window.mapInstance = map;
        });
        
        map.on('error', function(e) {
          console.error('[Map] Error:', e.error ? e.error.message : 'Unknown');
          updateStatus('Error: ' + (e.error ? e.error.message : 'Unknown'));
        });
        
        // 10秒超时检测
        setTimeout(function() {
          if (!window.mapInstance) {
            updateStatus('Map loading timeout - network may be slow');
          }
        }, 10000);
        
        // 动态控制函数
        window.flyTo = function(lng, lat, zoom) {
          if (window.mapInstance) {
            window.mapInstance.flyTo({ center: [lng, lat], zoom: zoom || 14, essential: true });
          }
        };
        window.setCenter = function(lng, lat) {
          if (window.mapInstance) window.mapInstance.setCenter([lng, lat]);
        };
        window.setZoom = function(zoom) {
          if (window.mapInstance) window.mapInstance.setZoom(zoom);
        };
        window.addMarker = function(id, lng, lat, title, color) {
          if (window.mapInstance) {
            return new mapboxgl.Marker({ color: color || '#FF6B35' })
              .setLngLat([lng, lat])
              .setPopup(new mapboxgl.Popup({ offset: 25 }).setHTML('<strong>' + title + '</strong>'))
              .addTo(window.mapInstance);
          }
        };
        
      } catch (err) {
        console.error('[Map] Init error:', err.message);
        updateStatus('Error: ' + err.message);
        document.getElementById('loading').innerHTML = '<div class="error-message">' + err.message + '</div>';
      }
    }
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

  // 动态飞行到指定位置
  flyTo(lng: number, lat: number, zoom?: number): void {
    const zoomLevel = zoom !== undefined ? zoom : 14;
    this.controller.runJavaScript(`window.flyTo(${lng}, ${lat}, ${zoomLevel})`);
  }

  // 设置地图中心点
  setCenter(lng: number, lat: number): void {
    this.controller.runJavaScript(`window.setCenter(${lng}, ${lat})`);
  }

  // 设置缩放级别
  setZoom(zoom: number): void {
    this.controller.runJavaScript(`window.setZoom(${zoom})`);
  }

  // 动态添加标记
  addMarker(id: number, lng: number, lat: number, title: string, color?: string): void {
    const markerColor = color !== undefined ? color : '#FF6B35';
    this.controller.runJavaScript(`window.addMarker(${id}, ${lng}, ${lat}, '${title}', '${markerColor}')`);
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
        .cacheMode(CacheMode.Default)
        .darkMode(WebDarkMode.Auto)
        .overviewModeAccess(true)
        .fileAccess(true)
        .imageAccess(true)
        .zoomAccess(true)
        .onControllerAttached(() => {
          // Load the map HTML when controller is attached
          console.info('[MapView] Controller attached, loading map...');
          try {
            const html = this.generateMapHtml();
            this.controller.loadData(html, 'text/html', 'UTF-8', '');
          } catch (err) {
            console.error('[MapView] Failed to load map:', JSON.stringify(err));
          }
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
          this.isLoading = false;
        })
        .onHttpErrorReceive((event) => {
          console.error('[MapView] HTTP Error:', event.response.getResponseCode());
        })
        // 监听来自 JS 的消息（标记点击等）
        .onConsole((event) => {
          // 解析来自 JS 的消息
          const message = event.message.getMessage();
          const level = event.message.getMessageLevel();
          // level: 1=DEBUG, 2=INFO, 3=WARN, 4=ERROR
          if (level >= 4) {
            console.error('[MapView-JS]', message);
          } else {
            console.info('[MapView-JS]', message);
          }
          return false;
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
