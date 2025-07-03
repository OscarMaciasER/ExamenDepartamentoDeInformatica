<template>
  <div class="container text-center" style="margin-top: 2%;">
    <div class="row" style="margin-bottom: 10px; text-align: left;">
      <h3>Inventario</h3>
    </div>
    <div class="row d-flex justify-content-end">
      <div class="col-md-3">
        <button class="btn btn-success" style="width:15%; float: right;"><i class="fa-solid fa-plus"></i></button>
      </div>
      <div class="col-md-2">
        <select class="form-select" style="width:100%;" aria-label="Default select example" v-model="selectedEstado">
          <option>Todos</option>
          <option v-for="estado in estados" :key="estado.Estatus" :value="estado.Estatus">{{ estado.Estatus }}</option>
        </select>
      </div>
      <div class="col-md-2">
        <select class="form-select" style="width: 100%;" aria-label="Default select example"
          v-model="selectedTipoEquipo">
          <option>Todos</option>
          <option v-for="tipo in tipoEquipos" :key="tipo.Tipo_Equipo" :value="tipo.Tipo_Equipo">{{ tipo.Tipo_Equipo }}
          </option>
        </select>
      </div>
      <div class="col-md-1">
        <button class="btn btn-primary" style="width: 100%;" @click="filtar"><i class="fas fa-search"></i></button>
      </div>
    </div>

    <div class="row" style="margin-top: 3%;">
      <table class="table table-striped table-hover">
        <thead>
          <tr>
            <th scope="col">Responsable TI</th>
            <th scope="col">Empleado Asignado</th>
            <th scope="col">Tipo de Equipo</th>
            <th scope="col">Fecha de Registro</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="equipo in equipos" :key="Responsable_TI">
            <th scope="row">{{ equipo.Responsable_TI }}</th>
            <td>{{ equipo.Asignado_A_Empleado }}</td>
            <td>{{ equipo.Tipo_Equipo }}</td>
            <td>{{ equipo.FechaRegistro }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>

  <div class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">Modal title</h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <p>Modal body text goes here.</p>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-primary">Save changes</button>
          <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'
// @ is an alias to /src

export default {
  name: 'HomeView',
  data() {
    return {
      equipos: [],
      tipoEquipos: [],
      estados: [],
      selectedEstado: 'Todos',
      selectedTipoEquipo: 'Todos'
    }
  },
  mounted() {
    axios.get('http://localhost:8000/api/equipos/')
      .then(response => {
        this.equipos = response.data;
      })
      .catch(error => {
        console.log(error);
      });

    axios.get('http://localhost:8000/api/tipoEquipos/')
      .then(response => {
        this.tipoEquipos = response.data;
      })
      .catch(error => {
        console.log(error);
      });

    axios.get('http://localhost:8000/api/estados/')
      .then(response => {
        this.estados = response.data;
      })
      .catch(error => {
        console.log(error);
      });
  },
  methods: {
    filtar() {
      axios.get('http://localhost:8000/api/equipos/', {
        params: {
          Tipo_Equipo: (this.selectedTipoEquipo == 'Todos' ? null : this.selectedTipoEquipo),
          Estatus: (this.selectedEstado == 'Todos') ? null : this.selectedEstado
        }
      })
        .then(response => {
          this.equipos = response.data;
        })
        .catch(error => {
          console.log(error);
        });
    }
  }
}
</script>
