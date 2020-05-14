﻿// ----------------------------------------------------------------------------------
//
// Copyright Microsoft Corporation
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------------------

namespace Microsoft.Azure.PowerShell.Cmdlets.HPCCache.Models
{
    using StorageCacheModels = Microsoft.Azure.Management.StorageCache.Models;

    /// <summary>
    /// PSHpcNfs3Target.
    /// </summary>
    public class PSHpcNfs3Target
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="PSHpcNfs3Target"/> class.
        /// </summary>
        /// <param name="nfs3Target">nfs3Target.</param>
        public PSHpcNfs3Target(StorageCacheModels.Nfs3Target nfs3Target)
        {
            this.Target = nfs3Target.Target;
            this.UsageModel = nfs3Target.UsageModel;
        }

        /// <summary>
        /// Gets or Sets NFS3 Target.
        /// </summary>
        public string Target { get; set; }

        /// <summary>
        /// Gets or Sets storageTarget UsageModel.
        /// </summary>
        public string UsageModel { get; set; }
    }
}