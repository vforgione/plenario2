/* global $:false */

import * as L from 'leaflet';
import 'leaflet-draw';
import Vue from 'vue';
import Vuex from 'vuex';
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw/dist/leaflet.draw.css';
import { FontAwesomeIcon, FontAwesomeLayers } from '@fortawesome/vue-fontawesome';
import Explorer from './components/Explorer.vue';

Vue.component('font-awesome-icon', FontAwesomeIcon);
Vue.component('font-awesome-layers', FontAwesomeLayers);
Vue.use(Vuex);

/**
 * A container that holds all application state. Changes to the store trigger
 * updates in store listeners (Vue components). The store cannot be mutated
 * directly. All mutations come through the interface provided by functions
 * under the mutations value.
 */
const store = new Vuex.Store({
  state: {
    query:    {},
    datasets: {},
  },

  mutations: {

    /**
     * Assign parameter values to the query state.
     *
     * @param {Object} state
     * @param {Object} params
     */
    assignQuery(state, params) {
      Vue.set(state, 'query', Object.assign(state.query, params));
    },
  },
});

// So current Leaflet implementation doesn't break
window.L = L;

// Only mount Vue once page has loaded
$(() => {
  new Vue({
    components: { Explorer },

    /**
     * Inject the `store` into all child components. Any children of this root
     * component will have access to a `$store` property containing the
     * application state.
     */
    store,
  }).$mount('#app');
});
