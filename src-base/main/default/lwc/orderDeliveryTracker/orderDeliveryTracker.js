/* global L */
import { LightningElement, api } from "lwc";
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
import LEAFLET from "@salesforce/resourceUrl/leafletjs";

const MAP_ICONS_PATH = "/resource/map_icons/";
const ICON_NAMES = ["food", "car", "home"];

const LEAFLET_NOT_LOADED = 0;
const LEAFLET_LOADING = 1;
const LEAFLET_READY = 2;

export default class DeliveryTracker extends LightningElement {
  // Map
  leafletState = LEAFLET_NOT_LOADED;
  map;
  markerLayer;

  @api mapMarkers;

  async renderedCallback() {
    if (this.leafletState === LEAFLET_NOT_LOADED) {
      await this.initializeLeaflet();
    }
  }

  async initializeLeaflet() {
    try {
      // Leaflet is loading
      this.leafletState = LEAFLET_LOADING;

      // Load resource files
      await Promise.all([loadScript(this, `${LEAFLET}/leaflet.js`), loadStyle(this, `${LEAFLET}/leaflet.css`)]);

      // Configure map
      const mapElement = this.template.querySelector(".map");
      this.map = L.map(mapElement, {
        zoomControl: false,
        tap: false
      });
      this.map.setView([37.7875941, -122.400459], 16);
      this.map.scrollWheelZoom.disable();
      L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
        maxZoom: 19,
        attribution: "© OpenStreetMap"
      }).addTo(this.map);

      // Leaflet is ready
      this.leafletState = LEAFLET_READY;

      // Display markers
      this.displayMarkers();
    } catch (error) {
      const message = error.message || error.body.message;
      console.error("Error loading Leaflet", message);
    }
  }

  displayMarkers() {
    // Stop if leaflet isn't ready yet
    if (this.leafletState !== LEAFLET_READY) {
      return;
    }

    // Remove previous layer from map if it exits
    if (this.markerLayer) {
      this.map.removeLayer(this.markerLayer);
    }

    // Prepare markers
    const markers = this.mapMarkers.map((item, index) => {
      const latLng = [item.latitude, item.longitude];
      const marker = L.marker(latLng, {
        icon: this.getMapIcon(ICON_NAMES[index])
      });
      return marker;
    });

    // Create a layer with markers and add it to map
    this.markerLayer = L.layerGroup(markers);
    this.markerLayer.addTo(this.map);
  }

  getMapIcon(iconName) {
    return L.icon({
      iconUrl: `${MAP_ICONS_PATH}${iconName}.png`,
      //shadowUrl: 'leaf-shadow.png',
      iconSize: [50, 40], // size of the icon (original 400x320)
      //shadowSize:   [50, 64], // size of the shadow
      iconAnchor: [25, 40], // point of the icon which will correspond to marker's location
      //shadowAnchor: [4, 62],  // the same for the shadow
      popupAnchor: [-3, -76] // point from which the popup should open relative to the iconAnchor
    });
  }
}
