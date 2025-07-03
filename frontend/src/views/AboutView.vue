<template>
  <div class="container text-center" style="margin-top: 2%;">
    <div class="row" style="margin-bottom: 10px; text-align: left;">
      <h3>Solicitudes</h3>
    </div>
    <div class="row d-flex justify-content-end">
      <div class="col-md-3">
        <button class="btn btn-success" style="width:15%; float: right;"><i class="fa-solid fa-plus"></i></button>
      </div>
    </div>

    <div class="row" style="margin-top: 3%;">
      <table class="table table-striped table-hover">
        <thead>
          <tr>
            <th scope="col" class="d-none">Id Solicitud</th>
            <th scope="col">Nombre</th>
            <th scope="col">Solicitante</th>
            <th scope="col">Estatus</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="solicitud in solicitudes" :key="solicitud.Id_Solicitud">
            <th scope="row" class="d-none">{{ solicitud.Id_Solicitud }}</th>
            <td @click="verDetalle(solicitud.Id_Solicitud)"
              style="cursor: pointer; color: green; text-decoration: underline;">
              {{ solicitud.Nombre }}
            </td>
            <td>{{ solicitud.Solicitante }}</td>
            <td>
              <span v-if="solicitud.Estatus.trim() === 'Pendiente'" @click="propuesta(solicitud.Id_Solicitud)"
                style="cursor: pointer; color: blue; text-decoration: underline;">
                {{ solicitud.Estatus }}
              </span>
              <span v-else>
                {{ solicitud.Estatus }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>

  <div class="modal" tabindex="-1" role="dialog" ref="modal">
    <div class="modal-dialog modal-xl" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">{{ modalTipo === 'propuesta' ? 'Propuesta de Asignación' : 'Detalle de la Solicitud' }}</h5>
        </div>
        <div class="modal-body">
          <div v-if="modalTipo === 'propuesta'">
            <h3 style="text-align: center;margin-top: 5%; margin-bottom:10%;">Equipos propuesta</h3>
            <table class="table table-striped table-hover" style="width: 100%;">
              <thead>
                <tr>
                  <th scope="col" class="d-none">Id_Con_Equipo</th>
                  <th scope="col">Rol</th>
                  <th scope="col">Persona</th>
                  <th scope="col" class="d-none">Id_Equipo</th>
                  <th scope="col">Tipo_Equipo</th>
                  <th scope="col">Modelo</th>
                  <th scope="col">Numero_Serie</th>
                  <th scope="col">Costo</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="equipo in conEquipo" :key="equipo.Id_Con_Equipo">
                  <td class="d-none">{{ equipo.Id_Con_Equipo }}</td>
                  <td>{{ equipo.Rol }}</td>
                  <td>{{ equipo.Persona }}</td>
                  <td class="d-none">{{ equipo.Id_Equipo }}</td>
                  <td>{{ equipo.Tipo_Equipo }}</td>
                  <td>{{ equipo.Modelo }}</td>
                  <td>{{ equipo.Numero_Serie }}</td>
                  <td>{{ equipo.Costo }}</td>
                </tr>
              </tbody>
            </table>

            <h3 style="text-align: center; margin-top:5%;margin-bottom: 10%;">Sin existencia</h3>
            <table class="table table-striped table-hover" style="width: 100%;">
              <thead>
                <tr>
                  <th scope="col" class="d-none">Id_Sin_Equipo</th>
                  <th scope="col">Rol</th>
                  <th scope="col">Tipo_Equipo</th>
                  <th scope="col">Persona</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in sinEquipo" :key="item.Id_Sin_Equipo">
                  <td class="d-none">{{ item.Id_Sin_Equipo }}</td>
                  <td>{{ item.Rol }}</td>
                  <td>{{ item.Tipo_Equipo }}</td>
                  <td>{{ item.Persona }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-else-if="modalTipo === 'detalle' && detalleSolicitud">
            <h3 style="text-align: center; margin-top:5%;margin-bottom: 5%;">Detalle de la solicitud</h3>
            <table class="table table-striped table-hover" style="width: 100%;">
              <thead>
                <tr>
                  <th scope="col" class="d-none">Rol</th>
                  <th scope="col">Cantidad</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in detalleSolicitud" :key="item.Rol">
                  <td>{{ item.Rol }}</td>
                  <td>{{ item.Cantidad }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal" @click="cerrarModal">Cerrar</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import * as bootstrap from 'bootstrap'
import axios from 'axios'
// @ is an alias to /src

export default {
  data() {
    return {
      solicitudes: [],
      conEquipo: [],
      sinEquipo: [],
      modalInstance: null,
      modalTipo: null,
      detalleSolicitud: null
    }
  },
  mounted() {
    this.modalInstance = new bootstrap.Modal(this.$refs.modal)
    axios.get('http://127.0.0.1:8000/api/solicitudes/')
      .then(response => {
        this.solicitudes = response.data;
      })
      .catch(error => {
        console.log(error);
      });
  },
  methods: {
    propuesta(Id_Solicitud) {
      console.log("hola");
      axios.get('http://127.0.0.1:8000/api/propuesta/', {
        params: {
          Id_Solicitud: Id_Solicitud,
        }
      })
        .then(response => {
          this.modalTipo = 'propuesta';
          this.conEquipo = response.data.con_equipo;
          this.sinEquipo = response.data.sin_equipo;
          this.abrirModal();
        })
        .catch(error => {
          console.log('Error al obtener solicitud:', error);
        });
    },
    verDetalle(Id_Solicitud) {
      axios.get('http://localhost:8000/api/solicitudes/detalle/', {
        params: { Id_Solicitud }
      })
        .then(response => {
          this.detalleSolicitud = response.data;
          this.modalTipo = 'detalle';
          this.abrirModal();
        })
        .catch(error => {
          console.log('Error al obtener detalle:', error);
        });
    },
    abrirModal() {
      this.modalInstance.show()
    },
    cerrarModal() {
      this.modalInstance.hide();
      this.modalTipo = null;
      this.detalleSolicitud = null;
      this.conEquipo = [];
      this.sinEquipo = [];
      this.modalInstance.hide()
    }
  }
}
</script>