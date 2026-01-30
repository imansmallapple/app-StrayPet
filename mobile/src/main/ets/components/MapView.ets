// MapView Component - Mapbox GL JS via WebView
// Load map HTML from rawfile
// Following ArkTS strict typing rules

import { webview } from '@kit.ArkWeb';

// Interface for marker JSON data
interface MarkerJsonData {
  id: number;
  latitude: number;
  longitude: number;
  title: string;
  description: string;
  color: string;
  imageUrl: string;
}

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

  // 转换为 JSON 对象
  toJson(): MarkerJsonData {
    const data: MarkerJsonData = {
      id: this.id,
      latitude: this.latitude,
      longitude: this.longitude,
      title: this.title,
      description: this.description,
      color: this.color,
      imageUrl: this.imageUrl
    };
    return data;
  }
}

@Component
export struct MapView {
  @Prop markers: MapMarker[] = [];
  @Prop centerLat: number = 39.9042;
  @Prop centerLng: number = 116.4074;
  @Prop zoom: number = 10;
  @Prop mapboxToken: string = '';
  @Prop showStaticFallback: boolean = false;  // 默认不显示静态地图，直接重试
  // 标记点击回调
  onMarkerClick?: (marker: MapMarker) => void;

  private controller: webview.WebviewController = new webview.WebviewController();
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State mapReady: boolean = false;
  @State retryCount: number = 0;  // 重试计数
  private initTimeout: number = -1;  // 超时定时器

  // 获取静态地图 URL（作为备用）
  private getStaticMapUrl(): string {
    const markerStr = this.markers.length > 0
      ? this.markers.map((m: MapMarker) => `pin-s+${m.color.replace('#', '')}(${m.longitude},${m.latitude})`).join(',')
      : `pin-s+FF6B35(${this.centerLng},${this.centerLat})`;
    return `https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/${markerStr}/${this.centerLng},${this.centerLat},${this.zoom},0/400x300@2x?access_token=${this.mapboxToken}`;
  }

  // 将 markers 转换为 JSON 字符串
  private markersToJson(): string {
    const arr: MarkerJsonData[] = [];
    for (let i = 0; i < this.markers.length; i++) {
      arr.push(this.markers[i].toJson());
    }
    return JSON.stringify(arr);
  }

  // 初始化地图（在页面加载完成后调用）
  private initializeMap(): void {
    console.info('[MapView] Initializing map...');
    
    // 清除之前的超时定时器
    if (this.initTimeout !== -1) {
      clearTimeout(this.initTimeout);
    }
    
    // 设置 15 秒超时
    this.initTimeout = setTimeout(() => {
      if (this.isLoading && !this.mapReady) {
        console.warn('[MapView] Map init timeout, retrying...');
        this.retryInit();
      }
    }, 15000);
    
    const script = `initMap('${this.mapboxToken}', ${this.centerLng}, ${this.centerLat}, ${this.zoom})`;
    this.controller.runJavaScript(script)
      .then((result: string) => {
        console.info('[MapView] initMap result:', result);
        if (result.includes('success')) {
          clearTimeout(this.initTimeout);
          this.initTimeout = -1;
          this.mapReady = true;
          this.isLoading = false;
          this.hasError = false;
          // 添加标记
          if (this.markers.length > 0) {
            this.addMarkersToMap();
          }
        } else {
          this.retryInit();
        }
      })
      .catch((err: Error) => {
        console.error('[MapView] initMap error:', err.message);
        this.retryInit();
      });
  }
  
  // 重试初始化
  private retryInit(): void {
    this.retryCount++;
    if (this.retryCount < 3) {
      console.info('[MapView] Retry attempt', this.retryCount);
      // 延迟 1 秒后重试
      setTimeout(() => {
        this.initializeMap();
      }, 1000);
    } else {
      // 超过重试次数，显示错误
      this.hasError = true;
      this.isLoading = false;
      this.errorMessage = 'Map loading failed. Tap to retry.';
    }
  }

  // 添加标记到地图
  private addMarkersToMap(): void {
    if (!this.mapReady || this.markers.length === 0) return;

    const markersJson = this.markersToJson();
    console.info('[MapView] Adding markers with JSON:', markersJson.substring(0, 500));
    // 只转义单引号，因为外层用单引号包裹
    const script = `addMarkers('${markersJson.replace(/'/g, "\\'")}')`;
    this.controller.runJavaScript(script)
      .then(() => {
        console.info('[MapView] Markers added');
      })
      .catch((err: Error) => {
        console.error('[MapView] Add markers error:', err.message);
      });
  }

  // 飞行到指定位置
  flyTo(lng: number, lat: number, zoom?: number): void {
    if (!this.mapReady) return;
    const z = zoom !== undefined ? zoom : 14;
    this.controller.runJavaScript(`flyTo(${lng}, ${lat}, ${z})`);
  }

  // 设置中心点
  setCenter(lng: number, lat: number): void {
    if (!this.mapReady) return;
    this.controller.runJavaScript(`setCenter(${lng}, ${lat})`);
  }

  // 设置缩放级别
  setZoom(zoom: number): void {
    if (!this.mapReady) return;
    this.controller.runJavaScript(`setZoom(${zoom})`);
  }

  // 清除所有标记
  clearMarkers(): void {
    if (!this.mapReady) return;
    this.controller.runJavaScript('clearMarkers()');
  }

  // 动态添加单个标记
  addMarker(marker: MapMarker): void {
    if (!this.mapReady) return;
    const script = `addMarker(${marker.id}, ${marker.longitude}, ${marker.latitude}, '${marker.title.replace(/'/g, "\\'")}', '${marker.description.replace(/'/g, "\\'")}', '${marker.color}')`;
    this.controller.runJavaScript(script);
  }

  aboutToAppear(): void {
    console.info('[MapView] aboutToAppear, token:', this.mapboxToken.substring(0, 10) + '...');
  }
  
  aboutToDisappear(): void {
    // 清除超时定时器
    if (this.initTimeout !== -1) {
      clearTimeout(this.initTimeout);
      this.initTimeout = -1;
    }
  }

  build() {
    Stack() {
      if (this.hasError) {
        // 显示错误和重试按钮
        Column() {
          SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
            .fontSize(48)
            .fontColor(['#F44336'])
          
          Text(this.errorMessage.length > 0 ? this.errorMessage : 'Map loading failed')
            .fontSize(14)
            .fontColor('#757575')
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)
          
          Button('Retry')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#4CAF50')
            .borderRadius(20)
            .margin({ top: 16 })
            .onClick(() => {
              // 重置状态并重试
              this.hasError = false;
              this.isLoading = true;
              this.mapReady = false;
              this.retryCount = 0;
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F5F5F5')
        .padding(32)
      } else {
        Web({ src: $rawfile('mapbox.html'), controller: this.controller })
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .geolocationAccess(true)
          .mixedMode(MixedMode.All)
          .cacheMode(CacheMode.Default)
          .onPageEnd(() => {
            console.info('[MapView] Page loaded, initializing...');
            // 页面加载完成后初始化地图，loading 状态在 initializeMap 成功后才改变
            this.initializeMap();
          })
          .onErrorReceive((event) => {
            console.error('[MapView] Error:', JSON.stringify(event));
            this.hasError = true;
            this.isLoading = false;
          })
          .onConsole((event) => {
            const msg = event.message.getMessage();
            const level = event.message.getMessageLevel();
            if (level >= 4) {
              console.error('[MapView-JS]', msg);
              // 捕获具体的错误信息
              if (msg.includes('not loaded') || msg.includes('WebGL') || msg.includes('network')) {
                this.errorMessage = msg.replace('[Map] ', '');
              }
            } else {
              console.info('[MapView-JS]', msg);
            }
            // 检测地图加载成功
            if (msg.includes('loaded successfully')) {
              this.isLoading = false;
              this.hasError = false;
            }
            // 检测标记点击事件
            if (msg.startsWith('[MarkerClick]:')) {
              const markerId = parseInt(msg.replace('[MarkerClick]:', ''));
              console.info('[MapView] Marker clicked:', markerId);
              // 触发回调
              if (this.onMarkerClick !== undefined) {
                // 查找对应的 marker
                for (let i = 0; i < this.markers.length; i++) {
                  if (this.markers[i].id === markerId) {
                    this.onMarkerClick(this.markers[i]);
                    break;
                  }
                }
              }
            }
            return false;
          })
          .width('100%')
          .height('100%')
      }

      if (this.isLoading && !this.hasError) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color('#4CAF50')
          Text('Loading map...')
            .fontSize(13)
            .fontColor('#757575')
            .margin({ top: 8 })
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
