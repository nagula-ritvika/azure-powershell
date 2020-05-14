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

using Microsoft.Azure.Management.CosmosDB.Models;

namespace Microsoft.Azure.Commands.CosmosDB.Models
{

    public class PSCompositePath
    {
        public PSCompositePath()
        {
        }

        public PSCompositePath(CompositePath compositePath)
        {
            if (compositePath == null)
            {
                return;
            }

            Path = compositePath.Path;
            Order = compositePath.Order;
        }

        //
        // Summary:
        //     Gets or sets the path for which the indexing behavior applies to. Index paths
        //     typically start with root and end with wildcard (/path/*)
        public string Path { get; set; }
        //
        // Summary:
        //     Gets or sets sort order for composite paths. Possible values include: 'Ascending',
        //     'Descending'
        public string Order { get; set; }

        public static CompositePath ToSDKModel(PSCompositePath pSCompositePath)
        {
            if (pSCompositePath == null)
            {
                return null;
            }

            return new CompositePath
            {
                Order = pSCompositePath.Order,
                Path = pSCompositePath.Path
            };
        }
    }
}
